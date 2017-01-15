#!/bin/bash

set -u

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

export IID=${1}
export OUT_DIR=${STATIC_DIR}/dec-source/${IID}

if [[ ! -d ${OUT_DIR} ]]; then
	mkdir -p ${OUT_DIR}
fi

# extract the files from the image tarball according to the database information
echo "Extracting binaries......"
tar xf ${FIRMWARE_DIR}/${IID}.tar.gz -C ${OUT_DIR} $(psql -U firmadyne -d firmware -c "select filename from object_to_image where iid=${IID} and score>0 and (mime='application/x-executable; charset=binary' or mime='application/x-object; charset=binary' or mime='application/x-sharedlib; charset=binary') order by score DESC;" | tail -n+3 | head -n-2 | sed -e 's/^ /\./')

# decompile the executables
echo "Decompiling binaries......"
find ${OUT_DIR} -type f -exec bash -c 'nocode "$0" > "$0".dec.c; rm -f "$0"' {} \;

# use flawfinder to do the source-code static analysis
echo "Static analysis using flawfinder......"
cd ${OUT_DIR}	# in order not to show the full path in the output results
find . -type f -name '*.dec.c' -exec bash -c 'flawfinder -cC "$0" > "$0".out; rm -f "$0"' {} \;
cd -
