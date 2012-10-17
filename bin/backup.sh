#!/bin/sh

# Adlibre Backup - Backup Single Host

CWD="$(dirname $0)/"

# Source Config
. ${CWD}../etc/backup.conf

# Source Functions
. ${CWD}functions.sh;

HOST=$1
ANNOTATION=${2-none}
EXPIRY=$(expr ${3-$EXPIRY} * 24 * 60 * 60 + $(date +%s)) # Convert expiry to unix epoc
HOSTS_DIR="/${ZPOOL_NAME}/hosts/"
LOCKFILE="/var/run/$(basename $0 | sed s/\.sh//)-${HOST}.pid"
LOGFILE="${HOSTS_DIR}${HOST}/l/backup.log"

if [ ! $(whoami) = "root" ]; then
    echo "Error: Must run as root."
    exit 99
fi

if [ ! ${HOST} ]; then
    echo "Usage: backup.sh <hostname> <annotation> <expiry-in-days>."
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
if [ -f  "${HOSTS_DIR}${HOST}/c/backup.conf" ]; then
    . "${HOSTS_DIR}${HOST}/c/backup.conf"
else
    echo "Error: Invalid host or host config not found."
    exit 99
fi

# Check to see if the host backup is disabled.
if [ "${DISABLED}" == "true" ];  then
    logMessage 1 $LOGFILE "Info: ${HOST} backup disabled by config."
    exit 0
fi

# expand excludes
for e in $EXCLUDE $EXCLUDE_ADDITIONAL; do
    RSYNC_EXCLUDES="$RSYNC_EXCLUDES --exclude=${e}"
done

# Do backup
rm -f ${LOGFILE} # delete logfile from host dir before we begin.
echo $EXPIRY > ${HOSTS_DIR}${HOST}/c/EXPIRY
echo $ANNOTATION > ${HOSTS_DIR}${HOST}/c/ANNOTATION

STARTTIME=$(date +%s)
RSYNC_CMD="rsync ${RSYNC_ARGS} ${RSYNC_ADDITIONAL_ARGS} ${RSYNC_EXCLUDES} ${SSH_USER}@${HOST}:'$BACKUP_PATHS' ${HOSTS_DIR}${HOST}/d/"
logMessage 1 $LOGFILE "Running: $RSYNC_CMD"
CMD=$($RSYNC_CMD)
RETVAL=$?
STOPTIME=$(date +%s)
RUNTIME=$(expr ${STOPTIME} - ${STARTTIME})

if [ "$RETVAL" = "0" ]; then
    raiseAlert "backup ${HOST}" 0 "Backup Successful. Runtime ${RUNTIME} seconds."
    logMessage 1 $LOGFILE "Backup Successful. Runtime ${RUNTIME} seconds."
else
    raiseAlert "backup ${HOST}" 2 "Backup Failed: ${CMD}."
    logMessage 3 $LOGFILE "Backup Failed: ${CMD}."
    exit 99
fi

# Create snapshot
SNAP_NAME="${HOST}@$(date +"%F-%X-%s")"
zfs snapshot $ZPOOL_NAME/hosts/${SNAP_NAME}
if [ "$?" = "0" ]; then
    raiseAlert "backup ${HOST}" 0 "Snapshot Successful"
    logMessage 1 $LOGFILE "Snapshot $SNAP_NAME Created"
else
    raiseAlert "backup ${HOST}" 2 "Snapshot Failed"
    logMessage 3 $LOGFILE "Snapshot $SNAP_NAME Failed"
    exit 99
fi

exit 0
