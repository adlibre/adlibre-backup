#!/usr/bin/env bash

# Adlibre Backup - Snapshot Pruner

# Manages snapshots in line with retention policy.

CWD="$(dirname $0)/"

# Source Config
. ${CWD}../etc/backup.conf

# Source Functions
. ${CWD}functions.sh;

HOSTS_DIR="/${POOL_NAME}/hosts/"
LOCKFILE="/var/run/$(basename $0 | sed s/\.sh//).pid"
LOGFILE="/${POOL_NAME}/logs/backup.log"
DRYRUN=
FORCE=

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
    --dry-run | -n)
        echo "Initiating dry run."
        DRYRUN="Dry run:"
        LOGFILE=/dev/stderr
        shift
        ;;
    --force | -f)
        echo "Forcing prune."
        FORCE=true
        shift
        ;;
    --)	# Stop option processing.
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

if [ -z "$HOSTS" -a "$1" == "" ] ; then
    echo "Please specify host or hostnames name as the arguments, or --all."
    echo "Usage: `basename $0` [ --dry-run | -n ] [ --force | -f ] [ --all | hostname ... ]"
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

for HOST in $HOSTS; do
    sourceHostConfig $HOSTS_DIR $HOST
    # Check to see if the host prune is disabled.
    if [ "${PRUNE}" == "false" ] && [ -z "$FORCE" ];  then
        logMessage 1 $LOGFILE "Info: ${HOST} prune disabled by config."
        PRUNE=true		# reset for the next pass through
	continue
    else
        logMessage 1 $LOGFILE "Info: Pruning snapshots for ${HOST}."
    fi
    # Prune the backup
    if [ -d ${HOSTS_DIR}${HOST}/.${POOL_TYPE}/snapshot ]; then
        SNAPSHOTS=$(find ${HOSTS_DIR}${HOST}/.${POOL_TYPE}/snapshot -maxdepth 1 -mindepth 1)
        for snapshot in $SNAPSHOTS; do
            if [ -f $snapshot/c/EXPIRY ]; then
                EXPIRY=$(cat $snapshot/c/EXPIRY 2> /dev/null)
                if [ $(date +%s) -gt $EXPIRY ]; then
                    logMessage 1 $LOGFILE "Info: Removing snapshot ${snapshot}."
                    SNAPSHOT=$(basename $snapshot)
                    if [ -n "$DRYRUN" ] ; then
                        echo $DRYRUN destroy ${POOL_NAME}/hosts/${HOST} ${SNAPSHOT}
                    else
                        storageDelete $POOL_TYPE ${POOL_NAME}/hosts/${HOST} ${SNAPSHOT}
                    fi
                fi
            fi
        done
    else
        logMessage 2 $LOGFILE "Warning: Host not found."
    fi
done

exit 0
