#!/usr/bin/env bash

# Adlibre Backup - Test NSCA Alerts

CWD="$(dirname $0)/"

# Source Config
. ${CWD}../etc/backup.conf

# Source Functions
. ${CWD}functions.sh;

HOST=$1
ANNOTATION=${2-none}

if [ ! ${HOST} ]; then
    echo "Usage: test-alerts.sh <hostname> <annotation>."
    exit 99
fi

raiseAlert "${ANNOTATION}" 0 "Test Message" ${HOST}
