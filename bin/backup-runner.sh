#!/bin/bash

# Adlibre Backup - Backup Runner - Backup Multiple hosts

CWD="$(dirname $0)/"

# Source Config
. ${CWD}../etc/backup.conf

# Source Functions
. ${CWD}functions.sh;

HOSTS_DIR="/${POOL_NAME}/hosts/"
LOCKFILE="/var/run/$(basename $0 | sed s/\.sh//).pid"
LOGFILE="/${POOL_NAME}/logs/backup.log"

if [ ! $(whoami) = "root" ]; then
    echo "Error: Must run as root."
    exit 99
fi

# Check to see if we are already running / locked, limit to one instance per host
if [ -f ${LOCKFILE} ] ; then
    logMessage 3 $LOGFILE "Error: Already running, or locked. Lockfile exists [$(ls -ld $LOCKFILE)]."
    exit 99
else
    echo $$ > ${LOCKFILE}
    # Upon exit, remove lockfile.
    trap "{ rm -f ${LOCKFILE}; }" EXIT
fi

showUsage() {
    echo "
Adlibre Backup

Backup Runner - Backup Multiple Hosts
    
  usage: bashup-runner.sh [ -c <comment> ] [hosts ...]
    
  options:
    -a | --all                 backup all hosts
    -c | --comment <comment>   backup annotation
    [hosts ...]                one or more hosts to backup
    -h                         this help message
    ";
}

# Parse Opts
while true; do
    case "$1" in
        -a | --all ) HOSTS=$(ls ${HOSTS_DIR}); shift ;;
        -c | --comment ) ANNOTATION=$2; shift 2 ;;
        -h | --help ) showUsage; exit 128 ;;
        -- ) shift; break ;;
        * ) if [ ! "$1" == "" ]; then HOSTS="$HOSTS $*"; fi; shift; break ;;
    esac
done

if [ "$HOSTS" == '' ]; then
    echo "Error: Please specify host or hostnames name as the arguments, or --all."
    showUsage
    exit 128
fi

logMessage 1 $LOGFILE "Info: Begin backup run of hosts $(echo ${HOSTS})" 

for host in $HOSTS; do
    logMessage 1 $LOGFILE "Info: Begining backup of ${host}" 
    ${CWD}backup.sh ${host} "${ANNOTATION}"
    if [ "$?" = "0" ]; then
        logMessage 1 $LOGFILE "Info: Completed backup of ${host}" 
	else
		logMessage 3 $LOGFILE "Error: Backup of ${host} encountered an error"
	fi
done

exit 0
