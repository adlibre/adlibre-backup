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
        command -v $RSYNC_BIN > /dev/null || echo "Warning: rsync not found. Please specify \$RSYNC_BIN location in backup.conf."
        if [ "$NSCA_ENABLED" == "true" ]; then
            command -v $NSCA_BIN > /dev/null || echo "Warning: send_nsca not found. Please specify \$NSCA_BIN location in backup.conf."
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
        *)
            echo "Warning: POOL_TYPE unknown."
            break
            ;;
    esac
}

