#!/usr/bin/env bash

# Adlibre Backup - monitor

# Sends process status information to Nagios / Icinga using NSCA passive check
# Replace this with your own monitor script to integrate with any third party
# monitoring system.

CWD="$(dirname $0)/"

# Source Config
. ${CWD}../etc/backup.conf

# Defaults
: ${NSCA_BIN:='/usr/sbin/send_nsca'}
: ${NSCA_CFG:='/etc/nagios/send_nsca.cfg'}
: ${NSCA_PORT:='5667'}
: ${4:=$(hostname)}

function die() {
    echo "Error: $1"
    exit 128

}

function usage() {
   echo "Usage: $0 <service-name> <return-code> <message> <optional hostname>"
   exit 1
}

# Tests
[ -z "$NSCA_SERVER" ] && die "NSCA_SERVER not set" || true
command -v $NSCA_BIN > /dev/null || die "send_nsca not found. Please specify \$NSCA_BIN location in backup.conf."

function raiseAlert () {
    # $1 - Service name that has been set up on nsca server
    # $2 - Return code 0=success, 1=warning, 2=critical
    # $3 - Message you want to send
    # $4 - Optional hostname
    # <host_name>,<svc_description>,<return_code>,<plugin_output>
    if [ -f ${NSCA_BIN} ]; then
        echo "${4},$1,$2,$3" | ${NSCA_BIN} -H ${NSCA_SERVER} \
        -p ${NSCA_PORT} -d "," -c ${NSCA_CFG} > /dev/null;
    else
        die "NSCA Plugin not found.";
    fi
}

raiseAlert "$1" "$2" "$3" "$4"
