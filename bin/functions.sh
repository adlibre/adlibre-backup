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
# Send passive alert information to Nagios / Icinga
#
raiseAlert () {
    # $1 - Service name that has been set up on nagios/nagiosdev server
    # $2 - Return code 0=success, 1=warning, 2=critical
    # $3 - Message you want to send
    # <host_name>,<svc_description>,<return_code>,<plugin_output>
    # defaults that can be overridden
    NAGIOS_DIR=${NAGIOS_DIR-/usr/sbin/}
    NAGIOS_CFG=${NAGIOS_CFG-/etc/nagios/}
    NAGIOS_PORT=${NAGIOS_PORT-5667}
    if [ -f ${NAGIOS_DIR}send_nsca ]; then
        echo "`hostname`,$1,$2,$3" | ${NAGIOS_DIR}send_nsca -H ${NAGIOS_SERVER} \
        -p ${NAGIOS_PORT} -d "," -c ${NAGIOS_CFG}send_nsca.cfg > /dev/null;
        echo "Debug: Message Sent to Nagios ($NAGIOS_SERVER): $1 $2 $3.";
    else
        echo "Warning: NSCA (Nagios) Plugin not found.";
    fi
}
