#!/bin/bash

set -e

if [[ ${USER} == "root" ]]; then
	echo "Please run this script without root privilege."
	exit 1
fi

if [ -e ../configure.sh ]; then
        source ../configure.sh
elif [ -e ./configure.sh ]; then
        source ./configure.sh
else
        echo "Error: Could not find 'configure.sh'!"
        exit 1
fi


for pkg in $(ls ${SCRIPT_DIR}/pkgs/)
do
	cd "${SCRIPT_DIR}/pkgs/${pkg}"
	makepkg -srcif --needed --noconfirm
done

