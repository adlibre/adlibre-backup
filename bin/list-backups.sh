#!/usr/bin/env bash

# Adlibre Backup - List backups for a host

CWD="$(dirname $0)/"

# Source Config
. ${CWD}../etc/backup.conf

# Source Functions
. ${CWD}functions.sh;

if [ ${HACK88} == '1' ]; then
    HOSTS_DIR="${MOUNT_POINT}/h/"
else
    HOSTS_DIR="${MOUNT_POINT}/hosts/"
fi

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

for host in $HOSTS; do
    if [ -d ${HOSTS_DIR}${host}/.${POOL_TYPE}/snapshot ]; then
        SNAPSHOTS=$(find ${HOSTS_DIR}${host}/.${POOL_TYPE}/snapshot -maxdepth 1 -mindepth 1 | sort)
        for snapshot in $SNAPSHOTS; do
            SNAPSHOT=$(basename $snapshot)
            EXPIRY=$(cat $snapshot/c/EXPIRY 2> /dev/null)
            ANNOTATION=$(cat $snapshot/c/ANNOTATION 2> /dev/null)
            if [ "$HACK88" == "1" ]; then
                . ${HOSTS_DIR}${host}/.zfs/snapshot/$SNAPSHOT/l/snap_data
                echo "$host ${SNAPSHOT}:${SNAP_NAME} $EXPIRY \"$ANNOTATION\""
            else
                echo "$host $SNAPSHOT $EXPIRY \"$ANNOTATION\""
            fi
        done
    fi
done

exit 0
