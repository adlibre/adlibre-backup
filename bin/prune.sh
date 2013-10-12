#!/bin/sh

# Adlibre Backup - Filesystem Snapshotter

# Manages snapshots in line with retention policy.

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

while test $# -gt 0; do
    case "$1" in
	--all | -a)
	    HOSTS=$(ls ${HOSTS_DIR})
	    shift
	    ;;
	--)		# Stop option processing.
	    shift; break
	    ;;
	-*)
	    echo >&2 "$0: unrecognized option \`$1'"
	    exit 99
	    ;;
	*)
	    break
	    ;;
    esac
done

if [ -z "$HOSTS" -a "x$1" = "x" ] ; then
    echo "Please specify host or hostnames name as the arguments, or --all."
    exit 99
elif [ -z "$HOSTS" ] ; then
    HOSTS=$@
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

for host in $HOSTS; do
    logMessage 1 $LOGFILE "Info: Pruning snapshots for ${host}."
    if [ -d ${HOSTS_DIR}${host}/.zfs/snapshot ]; then
        SNAPSHOTS=$(find ${HOSTS_DIR}${host}/.zfs/snapshot -maxdepth 1 -mindepth 1)
        for snapshot in $SNAPSHOTS; do
            if [ -f $snapshot/c/EXPIRY ]; then
                EXPIRY=$(cat $snapshot/c/EXPIRY 2> /dev/null)
                if [ $(date +%s) -gt $EXPIRY ]; then
                    logMessage 1 $LOGFILE "Info: Removing snapshot ${snapshot}."
                    SNAPSHOT=$(basename $snapshot)                    
                    zfs destroy ${ZPOOL_NAME}/hosts/${host}@${SNAPSHOT}
                fi
            fi
        done
    fi
done

exit 0
