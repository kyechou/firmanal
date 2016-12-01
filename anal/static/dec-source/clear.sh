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

if [ $# -ne 1 ]; then
	echo "Usage: $0 <image ID>"
	exit 1
fi

IID=${1}
WORK_DIR=${STATIC_DIR}/dec-source
EXTRACT_DIR=${WORK_DIR}/extract/${IID}
DEC_DIR=${WORK_DIR}/dec/${IID}
RESULT_DIR=${WORK_DIR}/result/${IID}

if [ -d ${EXTRACT_DIR} ]; then
	rm -rf ${EXTRACT_DIR}
fi
if [ -d ${DEC_DIR} ]; then
	rm -rf ${DEC_DIR}
fi
if [ -d ${RESULT_DIR} ]; then
	rm -rf ${RESULT_DIR}
fi
