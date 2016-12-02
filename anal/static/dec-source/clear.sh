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
WORK_DIR=${STATIC_DIR}/dec-source
DEC_DIR=${WORK_DIR}/dec/${IID}
OUT_DIR=${WORK_DIR}/out/${IID}

if [[ ! -d ${DEC_DIR} ]]; then
	rm -rf ${DEC_DIR}
fi
if [[ ! -d ${OUT_DIR} ]]; then
	rm -rf ${OUT_DIR}
fi
