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

if [ ! -d "/${ZPOOL_NAME}/hosts/" ]; then
    zfs create ${ZPOOL_NAME}/hosts
fi

zfs create ${ZPOOL_NAME}/hosts/${HOST}
mkdir /${ZPOOL_NAME}/hosts/${HOST}/c
mkdir /${ZPOOL_NAME}/hosts/${HOST}/d
mkdir /${ZPOOL_NAME}/hosts/${HOST}/l
cp /${ZPOOL_NAME}/etc/host_default.conf /${ZPOOL_NAME}/hosts/${HOST}/c/backup.conf
