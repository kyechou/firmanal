#!/bin/bash

set -eu

if [ -e ../../../configure.sh ]; then
	. ../../../configure.sh
elif [ -e ../../configure.sh ]; then
	. ../../configure.sh
elif [ -e ../configure.sh ]; then
	. ../configure.sh
elif [ -e ./configure.sh ]; then
	. ./configure.sh
else
	echo "Error: Could not find 'configure.sh'!"
	exit 1
fi

if [[ $# -ne 1 ]]; then
	echo "Usage: $0 <image ID>"
	exit 1
fi

IID=${1}
OUT_DIR=${STATIC_DIR}/dec-source/${IID}

if [[ -d ${OUT_DIR} ]]; then
	rm -rf ${OUT_DIR}
fi
