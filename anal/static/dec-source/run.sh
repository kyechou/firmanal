#!/bin/sh

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

if [ ! -d ${EXTRACT_DIR} ]; then
	mkdir -p ${EXTRACT_DIR}
fi
if [ ! -d ${DEC_DIR} ]; then
	mkdir -p ${DEC_DIR}
fi
if [ ! -d ${RESULT_DIR} ]; then
	mkdir -p ${RESULT_DIR}
fi

tar xf ${FIRMWARE_DIR}/${IID}.tar.gz -C ${EXTRACT_DIR} $(psql -U firmadyne -d firmware -c "select filename from object_to_image where mime='application/x-executable; charset=binary' order by score DESC;" | tail -n+3 | head -n-2 | sed -e 's/^ /\./')
