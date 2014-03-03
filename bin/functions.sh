#!/bin/sh

#
# Log Message to text file.
#
# Where Error Level is:
# 0=debug
# 1=info
# 2=warn
# 3=error
#
logMessage () {
    # $1 = Error level
    # $2 = logpath
    # $3 = message 
    DATE=$(date +"%F %X")
    if [ "$1" -ge "$LOG_LEVEL" ]; then
        echo "$DATE $3" >> ${2}
        if [ "$ECHO_LOG" -eq "1" ]; then
            echo $3
        fi
    fi
}

#
# Send passive check information to Nagios / Icinga using NSCA
#
raiseAlert () {
    # $1 - Service name that has been set up on nsca server
    # $2 - Return code 0=success, 1=warning, 2=critical
    # $3 - Message you want to send
    # $4 - Optional hostname
    # <host_name>,<svc_description>,<return_code>,<plugin_output>
    # defaults that can be overridden
    NSCA_BIN=${NSCA_BIN-/usr/sbin/send_nsca}
    NSCA_CFG=${NSCA_CFG-/etc/nagios/send_nsca.cfg}
    NSCA_PORT=${NSCA_PORT-5667}
    if [ -f ${NSCA_BIN} ]; then
        echo "${4-$(hostname)},$1,$2,$3" | ${NSCA_BIN} -H ${NSCA_SERVER} \
        -p ${NSCA_PORT} -d "," -c ${NSCA_CFG} > /dev/null;
    else
        echo "Warning: NSCA Plugin not found.";
    fi
}

#
# Source host config
#
sourceHostConfig() {
    
    # $1 = HOSTS_DIR
    # $2 = HOST
    if [ -f  "${1}${2}/c/backup.conf" ]; then
        . "${1}${2}/c/backup.conf"
        # Check Sanity of Config (unified with global config)
        command -v $RSYNC_BIN > /dev/null || echo "rsync not found. Please specify \$RSYNC_BIN location in backup.conf."
        command -v $NSCA_BIN > /dev/null || echo "send_nsca not found. Please specify \$NSCA_BIN location in backup.conf."
    else
        echo "Error: Invalid host or host config not found."
        exit 99
    fi
}
