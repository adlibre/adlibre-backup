#!/usr/bin/env bash

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
    DATE=$(date +"%F %T")
    if [ "$1" -ge "$LOG_LEVEL" ]; then
        echo "$DATE $3" >> ${2}
        if [ "$ECHO_LOG" -eq "1" ]; then
            echo $3
        fi
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
        command -v $RSYNC_BIN > /dev/null || echo "Warning: rsync not found. Please specify \$RSYNC_BIN location in backup.conf."
        if [ "$MONITOR_ENABLED" == "true" ]; then
            command -v $MONITOR_HANDLER > /dev/null || echo "Warning: MONITOR_HANDLER not found. Please specify a correct \$MONITOR_HANDLER location in backup.conf."
        fi
    else
        echo "Error: Invalid host or host config not found."
        exit 99
    fi
}

#
# Create Storage Subvolume
#
storageCreate() {
    # $1 = POOL_TYPE (zfs or btrfs)
    # $2 = path

    case "$1" in
        btrfs)
            btrfs subvolume create /${2}
            ;;
        zfs)
            zfs create ${2}
            ;;
        s3ql)
            mkdir /${2}
            ;;
        *)
            echo "Warning: POOL_TYPE unknown."
            break
            ;;
    esac
}

#
# Snapshot Storage Subvolume
#
storageSnapshot() {
    # $1 = POOL_TYPE (zfs or btrfs)
    # $2 = path
    # $3 = snapshot

    case "$1" in
        btrfs)
            btrfs subvolume snapshot -r /${2} /${2}/.btrfs/snapshot/${3}
            ;;
        zfs)
            zfs snapshot ${2}${3}
            ;;
        s3ql)
            mkdir -p /${2}/.s3ql/snapshot
            s3qlcp /${2} /${2}/.s3ql/snapshot/${3}
            s3qlctrl flushcache /${POOL_NAME}
            ;;
        *)
            echo "Warning: POOL_TYPE unknown."
            break
            ;;
    esac
}

#
# Delete Storage Subvolume
#
storageDelete() {
    # $1 = POOL_TYPE (zfs or btrfs)
    # $2 = path
    # $3 = snapshot (optional)

    case "$1" in
        btrfs)
            btrfs subvolume delete /${2}/.btrfs/snapshot/${3}
            ;;
        zfs)
            zfs destroy ${2}@${3}
            ;;
        s3ql)
            s3qlrm /${2}/.s3ql/snapshot/${3}
            s3qlctrl flushcache /${POOL_NAME}
            ;;
        *)
            echo "Warning: POOL_TYPE unknown."
            break
            ;;
    esac
}
