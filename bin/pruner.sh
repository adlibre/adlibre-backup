#!/bin/sh

# Adlibre Backup - Filesystem Snapshotter

# Manages snapshots in line with retention policy.

CWD="$(dirname $0)/"

# Source Config
. ${CWD}../etc/backup.conf

# Source Functions
. ${CWD}functions.sh;

HOSTS_DIR="/${ZPOOL_NAME}/hosts/"
LOCKFILE="/var/run/$(basename $0 | sed s/\.sh//).pid"
LOGFILE="${HOSTS_DIR}${HOST}/l/backup.log"

if [ ! $(whoami) = "root" ]; then
    echo "Error: Must run as root."
    exit 99
fi

if [ "$1" == '--all' ]; then
    HOSTS=$(ls ${HOSTS_DIR})
elif
    [ "$1" == '' ]; then
    echo "Please specify host or hostnames name as the arguments, or --all."
    exit 99
else
    HOSTS=$@
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

for host in $HOSTS; do
    logMessage 1 $LOGFILE "Info: Pruning snapshots for ${host}."
    if [ -d ${HOSTS_DIR}${host}/.zfs/snapshot ]; then
        SNAPSHOTS=$(find ${HOSTS_DIR}${host}/.zfs/snapshot -maxdepth 1 -mindepth 1)
        for snapshot in $SNAPSHOTS; do
            EXPIRY=$(cat $snapshot/c/EXPIRY 2> /dev/null)            
            if [ $(date +%s) -gt $EXPIRY ]; then
                logMessage 1 $LOGFILE "Info: Removing snapshot ${snapshot}."
                zfs destroy ${snapshot}
            fi
        done
    fi
done

exit 0