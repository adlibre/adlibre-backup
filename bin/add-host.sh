#!/bin/sh

HOST=$1

if [ ! $HOST ]; then
	echo "Please specify host name as the first argument."
	exit
fi


# zfs create backup/hosts
# zfs create backup/hosts/example.com
# zfs snapshot backup/hosts/example.com@foo
# zfs destroy backup/hosts/example.com@foo
