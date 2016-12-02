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
	mkdir -p ${DEC_DIR}
fi
if [[ ! -d ${OUT_DIR} ]]; then
	mkdir -p ${OUT_DIR}
fi

# extract the files from the image tarball according to the database information
tar xf ${FIRMWARE_DIR}/${IID}.tar.gz -C ${DEC_DIR} $(psql -U firmadyne -d firmware -c "select filename from object_to_image where mime='application/x-executable; charset=binary' order by score DESC;" | tail -n+3 | head -n-2 | sed -e 's/^ /\./')

# decompile the executables
find ${DEC_DIR} -type f -executable -exec bash -c 'nocode "$0" > "$0".dec.c' {} \;

# use flawfinder to do the source-code static analysis
