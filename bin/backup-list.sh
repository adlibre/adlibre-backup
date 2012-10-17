#!/bin/sh

# Adlibre Backup - List backups for a host

CWD="$(dirname $0)/"

# Source Config
. ${CWD}../etc/backup.conf

# Source Functions
. ${CWD}functions.sh;

HOSTS_DIR="/${ZPOOL_NAME}/hosts/"

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

echo "NAME SNAPSHOT EXPIRY ANNOTATION"
for host in $HOSTS; do
    if [ -d ${HOSTS_DIR}${host}/.zfs/snapshot ]; then
        SNAPSHOTS=$(find ${HOSTS_DIR}${host}/.zfs/snapshot -maxdepth 1 -mindepth 1)
        for snapshot in $SNAPSHOTS; do
            SNAPSHOT=$(basename $snapshot)
            EXPIRY=$(cat $snapshot/c/EXPIRY 2> /dev/null)
            ANNOTATION=$(cat $snapshot/c/ANNOTATION 2> /dev/null)
            echo "$host $SNAPSHOT $EXPIRY \"$ANNOTATION\""
        done
    fi
done

exit 0
