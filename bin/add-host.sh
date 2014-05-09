#!/bin/sh

# Adlibre Backup - Add new host

CWD="$(dirname $0)/"

# Source Config
. ${CWD}../etc/backup.conf

# Source Functions
. ${CWD}functions.sh;

HOST=$1

if [ ! $HOST ]; then
	echo "Please specify host name as the first argument."
	exit
fi

# Create hosts subvolume
if [ ! -d "/${POOL_NAME}/hosts/" ]; then
    zfs create ${POOL_NAME}/hosts
fi

# Create host subvolume
if [ ! -d "/${POOL_NAME}/hosts/${HOST}" ]; then
    zfs create ${POOL_NAME}/hosts/${HOST}
    mkdir /${POOL_NAME}/hosts/${HOST}/c
    mkdir /${POOL_NAME}/hosts/${HOST}/d
    mkdir /${POOL_NAME}/hosts/${HOST}/l
    cp /${POOL_NAME}/etc/host_default.conf /${POOL_NAME}/hosts/${HOST}/c/backup.conf
else
    echo "Error: Host already exists."
    exit 99
fi

# Try to copy ssh-key to host
ssh-copy-id -i ${SSH_KEY} ${HOST}