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

if check_number $1; then
    echo "Usage: mount.sh <image ID>"
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

DEVICE=/dev/mapper/loop0p1

echo "----Adding Device File----"
#/usr/bin/qemu-nbd --connect=/dev/${NBD} "${IMAGE}"
kpartx -a -v "${IMAGE}"
sleep 1

echo "----Making image directory----"
[[ ! -e "${IMAGE_DIR}" ]] && mkdir "${IMAGE_DIR}"

echo "----Mounting----"
#sudo /bin/mount /dev/nbd0p1 "${IMAGE_DIR}"
mount "${DEVICE}" "${IMAGE_DIR}"
