#!/bin/sh

HOST=$1

if [ ! $HOST ]; then
	echo "Please specify host name as the first argument."
	exit
fi


# setup backup zpool, set compression, set dedupe and inherit on backup/hosts 
# zfs create backup/hosts
# zfs set compression=gzip backup
# zfs set dedup=on backup
# zfs inherit -r compression backup/hosts
# zfs inherit -r dedup backup/hosts

# zfs create backup/hosts/example.com
# zfs snapshot backup/hosts/example.com@foo
# zfs destroy backup/hosts/example.com@foo

# zfs create backup/hosts/vz01.in.adlibre.net
# mkdir hosts/vz01.in.adlibre.net/c
# mkdir hosts/vz01.in.adlibre.net/d
# mkdir hosts/vz01.in.adlibre.net/l
# cp etc/host_default.conf hosts/vz01.in.adlibre.net/c/backup.conf


