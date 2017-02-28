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
BIN_DIR=${DYNAMIC_DIR}/afl/${IID}-bin
OUT_DIR=${DYNAMIC_DIR}/afl/${IID}-out

[[ -d ${BIN_DIR} ]] && rm -rf ${BIN_DIR}
[[ -d ${OUT_DIR} ]] && rm -rf ${OUT_DIR}
