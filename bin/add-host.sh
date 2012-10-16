#!/bin/sh

# Adlibre Backup - Add new host

CWD="$(dirname $0)/"

# Source Config
. ${CWD}../etc/backup.conf

# Source Functions
. ${CWD}functions.sh;

HOST=$1
LOGFILE="${HOSTS_DIR}${HOST}/l/backup.log"

if [ ! $HOST ]; then
	echo "Please specify host name as the first argument."
	exit
fi

zfs create ${ZPOOL_NAME}/hosts/${HOSTNAME}
mkdir /${ZPOOL_NAME}/hosts/${HOSTNAME}/c
mkdir /${ZPOOL_NAME}/hosts/${HOSTNAME}/d
mkdir /${ZPOOL_NAME}/hosts/${HOSTNAME}/l
cp /${ZPOOL_NAME}/etc/host_default.conf /${ZPOOL_NAME}/hosts/vz01.in.adlibre.net/c/backup.conf
