#!/usr/bin/env bash

# Adlibre Backup - List status of most recent backup

CWD="$(dirname $0)/"

# Source Config
. ${CWD}../etc/backup.conf

# Source Functions
. ${CWD}functions.sh;

HOSTS_DIR="/${POOL_NAME}/hosts/"

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
    backup=${HOSTS_DIR}${host}
    ANNOTATION=$(cat $backup/c/ANNOTATION 2> /dev/null)
    STATUS=$(cat $backup/l/STATUS 2> /dev/null)
    if [ -d ${HOSTS_DIR}${host}/.${POOL_TYPE}/snapshot ]; then
        SNAP=$(find ${HOSTS_DIR}${host}/.${POOL_TYPE}/snapshot -maxdepth 1 -mindepth 1 | sort -r | head -n 1)
	if [ "${POOL_TYPE}" == "btrfs" ]; then
            LATEST=$(basename "$SNAP" 2> /dev/null | cut -c 2-17)
        elif [ "${POOL_TYPE}" == "zfs" ]; then
            LATEST=$(basename "$SNAP" 2> /dev/null | cut -c 1-16)
        fi
        SIZE=$(du -hs "$SNAP" | awk '{ print $1 }')
    fi
    echo "$host $STATUS ${LATEST:-none} ${SIZE:-0} \"$ANNOTATION\""
done

exit 0
