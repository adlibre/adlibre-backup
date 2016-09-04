#!/usr/bin/env bash

# Adlibre Backup - Backup Single Host

CWD="$(dirname $0)/"

# Source Config
. ${CWD}../etc/backup.conf

# Source Functions
. ${CWD}functions.sh;

HOSTS_DIR="/${POOL_NAME}/hosts/"
DRYRUN=
FORCE=

if [ ! $(whoami) = "root" ]; then
    echo "Error: Must run as root."
    exit 99
fi

while test $# -gt 0; do
    case "$1" in
    --dry-run | -n)
        echo "Initiating dry run."
        DRYRUN="Dry run:"
        LOGFILE=/dev/stderr
        shift
        ;;    
    --force | -f)
        echo "Forcing backup."
        FORCE=true
        shift
        ;;
    --) # Stop option processing.
        shift; break
        ;;
    -*)
        echo >&2 "$0: unrecognized option \`$1'"
        exit 99
        ;;
    *)
        break
        ;;
    esac
done

HOST=$1
ANNOTATION=${2-none}
LOCKFILE="/var/run/$(basename $0 | sed s/\.sh//)-${HOST}.pid"
LOGFILE="${HOSTS_DIR}${HOST}/l/backup.log"
STATUSFILE="${HOSTS_DIR}${HOST}/l/STATUS"

if [ ! ${HOST} ]; then
    echo "Usage: backup.sh [--dry-run | -n ] [ --force | -f ] <hostname> <annotation> <expiry-in-days>."
    exit 99
fi

# Check to see if we are already running / locked, limit to one instance per host
if [ -f ${LOCKFILE} ] ; then
    logMessage 3 $LOGFILE "Error: Already running, or locked. Lockfile exists [$(ls -ld $LOCKFILE)]."
    exit 99
else
    echo $$ > ${LOCKFILE}
    # Upon exit, remove lockfile.
    trap "{ rm -f ${LOCKFILE}; }" EXIT
fi

# source host config
sourceHostConfig $HOSTS_DIR $HOST

# Options Overridable by backup.conf (or command line)

if [ -z "${3}" ]; then
	NUM_BACKUPS_TODAY=$(find ${HOSTS_DIR}${HOST}/.${POOL_TYPE}/snapshot -maxdepth 1 -mindepth 1 -name "@$(date +%F)*" | grep -v -e "-partial$" | wc -l)
	if [ "${NUM_BACKUPS_TODAY}" -eq "0" ]; then
		if [ -n "${EXPIRY_DAY}" ]; then EXPIRY=${EXPIRY_DAY}; fi
		if [ -n "${EXPIRY_WEEK}" -a "$(date +%u)" == "1" ]; then EXPIRY=${EXPIRY_WEEK}; fi
		if [ -n "${EXPIRY_MONTH}" -a "$(date +%-d)" == "1" ]; then EXPIRY=${EXPIRY_MONTH}; fi
		if [ -n "${EXPIRY_QUARTER}" -a "$(date +%-d)" == "1" -a "$(expr $(date '+%-m') % 3)" == "1" ]; then EXPIRY=${EXPIRY_QUARTER}; fi
		if [ -n "${EXPIRY_YEAR}" -a "$(date +%-j)" == "1" ]; then EXPIRY=${EXPIRY_YEAR}; fi
	fi
else
	EXPIRY=${3}
fi

if [ "${EXPIRY}" -gt "0" ]; then
	EXPIRY=$(expr ${EXPIRY} \* 24 \* 60 \* 60 + `date +%s`) # Convert expiry to unix epoc
fi

# Check to see if the host backup is disabled.
if [ "${DISABLED}" == "true" ] && [ -z "$FORCE" ];  then
    logMessage 1 $LOGFILE "Info: ${HOST} backup disabled by config."
    echo "disabled" > $STATUSFILE
    exit 0
fi

# expand excludes (with support for strings with escaped spaces)
eval "for e in $EXCLUDE $EXCLUDE_ADDITIONAL; do RSYNC_EXCLUDES=\"\$RSYNC_EXCLUDES --exclude='\${e}'\"; done"

# Generate rsync compatible backup path arguments
for P in $BACKUP_PATHS; do
   [ "${#P}" -ne "1" ] && P=${P%/}  # Remove trailing /
   P=":${P} "  # Add :
   RSYNC_BACKUP_PATHS="${RSYNC_BACKUP_PATHS}${P}"
done

# FIXME. Refactor do backup so we can properly handly dry-run
if [ -n "$DRYRUN" ] ; then
    echo "$DRYRUN Would have backed up $HOST with annotation ($ANNOTATION) and expiry ($EXPIRY)"
    exit
fi

# Do backup
(
rm -f ${LOGFILE} # delete logfile from host dir before we begin.
echo "inprogress" > $STATUSFILE
rm -f ${HOSTS_DIR}${HOST}/c/EXPIRY
if [ "${EXPIRY}" -gt "0" ]; then
	echo $EXPIRY > ${HOSTS_DIR}${HOST}/c/EXPIRY
fi
echo $ANNOTATION > ${HOSTS_DIR}${HOST}/c/ANNOTATION

STARTTIME=$(date +%s)

RSYNC_CMD="${RSYNC_BIN} ${RSYNC_ARGS} ${RSYNC_ADDITIONAL_ARGS} ${RSYNC_EXCLUDES} ${SSH_USER}@${RSYNC_HOST-${HOST}}${RSYNC_BACKUP_PATHS} ${HOSTS_DIR}${HOST}/d/"
logMessage 1 $LOGFILE "Running: $RSYNC_CMD"
CMD=$(eval $RSYNC_CMD 2>&1;)
RSYNC_RETVAL=$?
STOPTIME=$(date +%s)
RUNTIME=$(expr ${STOPTIME} - ${STARTTIME})

if [ "$RSYNC_RETVAL" = "0" ] || [ "${SNAPSHOT_ON_ERROR}" == "true" ]; then

    # Create snapshot
    if [ "$RSYNC_RETVAL" = "0" ]; then
        SNAP_NAME="@$(date +"%F-%X-%s")"
        echo "successful" > $STATUSFILE
    else
        SNAP_NAME="@$(date +"%F-%X-%s")-partial"
        echo "partial" > $STATUSFILE
    fi    
    storageSnapshot $POOL_TYPE $POOL_NAME/hosts/${HOST} ${SNAP_NAME}
    SNAPSHOT_RETVAL=$?
    
    if [ "$RSYNC_RETVAL" = "0" ] && [ "$SNAPSHOT_RETVAL" = "0" ]; then
        if [ "$NSCA_ENABLED" == "true" ]; then
            raiseAlert "backup ${HOST}" 0 "Backup Successful. Runtime ${RUNTIME} seconds."
            raiseAlert "${ANNOTATION}" 0 "Backup Successful. Runtime ${RUNTIME} seconds." ${HOST}
        fi
        logMessage 1 $LOGFILE "Backup Successful. Runtime ${RUNTIME} seconds."
    elif [ "$RSYNC_RETVAL" = "0" ] && [ "$SNAPSHOT_RETVAL" != "0" ]; then
        if [ "$NSCA_ENABLED" == "true" ]; then
            raiseAlert "backup ${HOST}" 2 "Backup succeeded, but Snapshot Failed"
        fi
        logMessage 3 $LOGFILE "Backup succeeded, but snapshot ${SNAP_NAME} Failed"
        exit 99
    elif [ "$RSYNC_RETVAL" != "0" ] && [ "$SNAPSHOT_RETVAL" = "0" ] && [ "${SNAPSHOT_ON_ERROR}" == "true" ]; then
        if [ "$NSCA_ENABLED" == "true" ]; then
            # Downgrade rsync failure error to nagios warning (because SNAPSHOT_ON_ERROR=true)
            raiseAlert "backup ${HOST}" 1 "Backup Failed: ${CMD}. Snapshotted anyway."
            raiseAlert "${ANNOTATION}" 1 "Backup Failed: ${CMD}. Snapshotted anyway." ${HOST}
        fi
        logMessage 3 $LOGFILE "Backup Error: ${CMD}. Rsync exited with ${RSYNC_RETVAL}. Snapshotted anyway."
        exit 99
    fi
else
    if [ "$NSCA_ENABLED" == "true" ]; then
        raiseAlert "backup ${HOST}" 2 "Backup Failed: ${CMD}."
        raiseAlert "${ANNOTATION}" 2 "Backup Failed: ${CMD}." ${HOST}
    fi
    logMessage 3 $LOGFILE "Backup Failed: ${CMD}. Rsync exited with ${RSYNC_RETVAL}."
    echo "failed" > $STATUSFILE
    exit 99
fi

) 2>&1 1>> ${LOGFILE} | tee -a ${LOGFILE} # stderr to console, stdout&stderr to logfile

exit 0
