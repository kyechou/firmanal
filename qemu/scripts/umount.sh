#!/bin/bash

set -e
set -u

if [ -e ../../configure.sh ]; then
    source ../../configure.sh
elif [ -e ../configure.sh ]; then
    source ../configure.sh
elif [ -e ./configure.sh ]; then
    source ./configure.sh
else
    echo "Error: Could not find 'configure.sh'!"
    exit 1
fi

if [[ $# -ne 1 ]]; then
    echo "Usage: umount.sh <image ID>"
    exit 1
fi

if check_number $1; then
    echo "Usage: umount.sh <image ID>"
    exit 1
fi
IID=${1}

if check_root; then
    echo "Error: This script requires root privileges!"
    exit 1
fi

echo "----Running----"
WORK_DIR=`get_vm ${IID}`
IMAGE=`get_fs ${IID}`
IMAGE_DIR=`get_fs_mount ${IID}`

DEVICE=$(get_device)

echo "----Unmounting----"
umount "${DEVICE}"

echo "----Disconnecting Device File----"
kpartx -d "${IMAGE}"
losetup -d "${DEVICE}" &>/dev/null
dmsetup remove "$(basename "${DEVICE}")" &>/dev/null
