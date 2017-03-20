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
EXPIRY=$(expr ${3-$EXPIRY} \* 24 \* 60 \* 60 + `date +%s`) # Convert expiry to unix epoc

# Check to see if the host backup is disabled.
if [ "${DISABLED}" == "true" ] && [ -z "$FORCE" ];  then
    logMessage 1 $LOGFILE "Info: ${HOST} backup disabled by config."
    echo "disabled" > $STATUSFILE
    exit 0
fi

# disable shell globbing to properly handle rsync patterns
set -f

# expand excludes (with support for strings with escaped spaces)
eval "for e in $EXCLUDE $EXCLUDE_ADDITIONAL; do RSYNC_EXCLUDES=\"\$RSYNC_EXCLUDES --exclude='\${e}'\"; done"

# expand includes (with support for strings with escaped spaces)
eval "for i in $INCLUDE $INCLUDE_ADDITIONAL; do RSYNC_INCLUDES=\"\$RSYNC_INCLUDES --include='\${i}'\"; done"

# enable shell globbing
set +f

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
echo $EXPIRY > ${HOSTS_DIR}${HOST}/c/EXPIRY
echo $ANNOTATION > ${HOSTS_DIR}${HOST}/c/ANNOTATION

STARTTIME=$(date +%s)

# allow overiding RSYNC_CMD if set
: ${RSYNC_CMD:="${RSYNC_BIN} ${RSYNC_ARGS} ${RSYNC_ADDITIONAL_ARGS} ${RSYNC_INCLUDES} ${RSYNC_EXCLUDES} ${SSH_USER}@${RSYNC_HOST-${HOST}}${RSYNC_BACKUP_PATHS} ${HOSTS_DIR}${HOST}/d/"}
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
        logMessage 1 $LOGFILE "Backup successful: ${CMD}. Rsync exited with ${RSYNC_RETVAL}"
    elif [ "$RSYNC_RETVAL" = "23" ] || [ "$RSYNC_RETVAL" = "24" ]; then
        SNAP_NAME="@$(date +"%F-%X-%s")-partial"
        echo "partial" > $STATUSFILE
        logMessage 2 $LOGFILE "Partial Backup: ${CMD}. Rsync exited with ${RSYNC_RETVAL}"
    else
        SNAP_NAME="@$(date +"%F-%X-%s")-failed"
        echo "failed" > $STATUSFILE
        logMessage 3 $LOGFILE "Backup failed: ${CMD}. Rsync exited with ${RSYNC_RETVAL}"
    fi
    storageSnapshot $POOL_TYPE $POOL_NAME/hosts/${HOST} ${SNAP_NAME}
    SNAPSHOT_RETVAL=$?

    if [ "$RSYNC_RETVAL" = "0" ] && [ "$SNAPSHOT_RETVAL" = "0" ]; then
        if [ "$MONITOR_ENABLED" == "true" ]; then
            $MONITOR_HANDLER "backup ${HOST}" 0 "Backup Successful. Runtime ${RUNTIME} seconds."
            $MONITOR_HANDLER "${ANNOTATION}" 0 "Backup Successful. Runtime ${RUNTIME} seconds." ${HOST}
        fi
        logMessage 1 $LOGFILE "Backup Successful. Runtime ${RUNTIME} seconds."
    elif [ "$RSYNC_RETVAL" = "0" ] && [ "$SNAPSHOT_RETVAL" != "0" ]; then
        if [ "$MONITOR_ENABLED" == "true" ]; then
            $MONITOR_HANDLER "backup ${HOST}" 2 "Backup succeeded, but Snapshot Failed"
        fi
        logMessage 3 $LOGFILE "Backup succeeded, but snapshot ${SNAP_NAME} Failed"
        exit 99
    elif [ "$RSYNC_RETVAL" != "0" ] && [ "$SNAPSHOT_RETVAL" = "0" ] && [ "${SNAPSHOT_ON_ERROR}" == "true" ]; then
        if [ "$MONITOR_ENABLED" == "true" ]; then
            # Downgrade rsync failure error to warning (1) (because SNAPSHOT_ON_ERROR=true)
            $MONITOR_HANDLER "backup ${HOST}" 1 "Backup Failed: ${CMD}. Snapshotted anyway."
            $MONITOR_HANDLER "${ANNOTATION}" 1 "Backup Failed: ${CMD}. Snapshotted anyway." ${HOST}
        fi
        exit 99
    fi
else
    if [ "$MONITOR_ENABLED" == "true" ]; then
        $MONITOR_HANDLER "backup ${HOST}" 2 "Backup Failed: ${CMD}."
        $MONITOR_HANDLER "${ANNOTATION}" 2 "Backup Failed: ${CMD}." ${HOST}
    fi
    logMessage 3 $LOGFILE "Backup Failed: ${CMD}. Rsync exited with ${RSYNC_RETVAL}."
    echo "failed" > $STATUSFILE
    exit 99
fi

) 2>&1 1>> ${LOGFILE} | tee -a ${LOGFILE} # stderr to console, stdout&stderr to logfile

exit 0
