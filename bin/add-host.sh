#!/usr/bin/env bash

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
if [ ${HACK88} == '1' ]; then
    HOSTS_DIR='h'
    if [ ! -d "${MOUNT_POINT}/h/" ]; then
        storageCreate $POOL_TYPE ${POOL_NAME}/h
        ln -s ${MOUNT_POINT}/h ${MOUNT_POINT}/hosts
    fi
else
    HOSTS_DIR='hosts'
    if [ ! -d "${MOUNT_POINT}/hosts/" ]; then
        storageCreate $POOL_TYPE ${POOL_NAME}/hosts
    fi
fi

# Create host subvolume
if [ ! -d "/${MOUNT_POINT}/${HOSTS_DIR}/${HOST}" ]; then
    storageCreate $POOL_TYPE ${POOL_NAME}/${HOSTS_DIR}/${HOST}
    mkdir ${MOUNT_POINT}/${HOSTS_DIR}/${HOST}/c
    mkdir ${MOUNT_POINT}/${HOSTS_DIR}/${HOST}/d
    mkdir ${MOUNT_POINT}/${HOSTS_DIR}/${HOST}/l
    cp ${MOUNT_POINT}/etc/host_default.conf ${MOUNT_POINT}/${HOSTS_DIR}/${HOST}/c/backup.conf
    if [ "${POOL_TYPE}" == "btrfs" ]; then 
        mkdir -p ${MOUNT_POINT}/hosts/${HOST}/.btrfs/snapshot
    fi
else
    echo "Error: Host already exists."
    exit 99
fi

# Try to copy ssh-key to host
ssh-copy-id -i ${SSH_KEY} ${HOST}
