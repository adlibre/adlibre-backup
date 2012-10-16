#!/bin/sh

# Adlibre Backup - Backup Runner - Backup Multiple hosts

CWD="$(dirname $0)/"

# Source Config
. ${CWD}../etc/backup.conf

# Source Functions
. ${CWD}functions.sh;

HOSTS_DIR="/${ZPOOL_NAME}/hosts/"
LOCKFILE="/var/run/$(basename $0 | sed s/\.sh//).pid"
LOGFILE="/${ZPOOL_NAME}/logs/backup.log"

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

if [ "$1" == '--all' ]; then
    HOSTS=$(ls ${HOSTS_DIR})
elif
    [ "$1" == '' ]; then
    echo "Please specify host or hostnames name as the arguments, or --all."
    exit 99
else
    HOSTS=$@
fi

logMessage 1 $LOGFILE "Info: begin backup run of hosts ${HOSTS}" 

for host in $HOSTS; do
    logMessage 1 $LOGFILE "Info: Begining backup of ${host}" 
    ${CWD}backup.sh ${host}
done

exit 0