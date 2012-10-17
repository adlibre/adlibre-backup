#!/bin/bash

#
# Remote Rsync backups with LVM snapshot.
# Andrew Cutler 2012 Adlibre Pty Ltd
#

#
# Install via an SSH forced command. If using a non root user, then sudo is required: 
# backup  ALL=NOPASSWD: /usr/bin/rsync, /usr/local/bin/rsync-lvm-snapshot.sh
# Make sure requiretty is off
#
# Add to authorized_keys:
# command="/usr/bin/sudo /usr/local/bin/rsync-lvm-snapshot.sh $SSH_ORIGINAL_COMMAND" ssh-dss AAAAB....
#

#
# Limitations: 
#  * Exclusions should work but need to check they are rooted in the snapshot point not the fs root. 
#  * Multiple paths not yet supported in a single run
#

# TODO: 
#  * Make this smarter so a single backup of / will automatically snapshot all LVM mounted filesystems in the path and return the filelist to rsync

# CONFIGURATION
RSYNC_ARGS=`shift; echo "$@"`
BACKUPPATH=`echo "${RSYNC_ARGS}" | sed 's/.* //'` # last argument
SNAP_SIZE='1G'
SNAP_SUFFIX='-rsync-snap'
SNAP_MNT='/mnt/'
DEBUG=false
DEBUG_LOG="/tmp/rsync-lvm-snapshot-$$.log"
# END CONFIGURATION


function getLVMDevice() {
    # $1 = '/home' returns /dev/vg_sys/lv_home
    ARG=`echo $1 | sed 's@/$@@g'` # remove trailing slash
    DEVICE=`grep " $ARG " /proc/mounts | awk '{print $1}' | xargs --no-run-if-empty lvdisplay -c 2> /dev/null | sed -e 's@:.*@@g;s@ @@g'`
    echo ${DEVICE}
    if ${DEBUG}; then
        echo "getLVMDevice: ${DEVICE}" >> $DEBUG_LOG
    fi
}

function isLVM() {
    CMD=`getLVMDevice ${1}`
    if [ "$CMD" = "" ]; then
        # is not LVM
        exit 1;
    else
        # is LVM
        exit 0;
    fi
}

function lvmBackup() {

    SRC_LV=`getLVMDevice ${BACKUPPATH}`
    SRC_NAME=`basename ${SRC_LV}`
    SNAP_LV="${SRC_LV}${SNAP_SUFFIX}"
    SNAP_NAME="${SRC_NAME}${SNAP_SUFFIX}"
    SNAP_MNT="${SNAP_MNT}${SNAP_NAME}"

    RSYNC_ARGS="`echo ${RSYNC_ARGS} | sed 's@[ ][^ ]*$@@'` ./" # replace last argument with relative path

    # Pre
    sync && \
    lvcreate -s ${SRC_LV} -n ${SNAP_NAME} -L ${SNAP_SIZE} 1> /dev/null && \
    mkdir -p ${SNAP_MNT} && \
    mount -o ro ${SNAP_LV} ${SNAP_MNT}

    # backup
    cd ${SNAP_MNT} && \
    /usr/bin/rsync ${RSYNC_ARGS}

    # post
    umount ${SNAP_MNT} && \
    lvremove -f ${SNAP_LV} 1> /dev/null && \
    rmdir ${SNAP_MNT}
}

function regularBackup() {
    # backup
    /usr/bin/rsync ${RSYNC_ARGS}
}

#
# Main code here
#

if ${DEBUG}; then
    echo "Started with args: $RSYNC_ARGS" >> $DEBUG_LOG
fi

T=`isLVM "$BACKUPPATH"`
if [ "$?" -eq "0" ]; then
    if ${DEBUG}; then
        echo "Performing an LVM backup: ${T}" >> $DEBUG_LOG
    fi
    lvmBackup
else
    if ${DEBUG}; then
        echo "Performing a regular backup: ${T}" >> $DEBUG_LOG
    fi
    regularBackup
fi
