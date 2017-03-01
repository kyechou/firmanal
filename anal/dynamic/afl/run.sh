#!/bin/bash

set -ue

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
MEMORY=2G

[[ ! -d ${BIN_DIR} ]] && mkdir -p ${BIN_DIR}
[[ ! -d ${OUT_DIR} ]] && mkdir -p ${OUT_DIR}

# extract the files from the image tarball according to the database information
echo "Extracting binaries......"
tar xf ${FIRMWARE_DIR}/${IID}.tar.gz -C ${BIN_DIR} $(psql -U firmadyne -d firmware -c "select filename from object_to_image where iid=${IID} and score>0 and (mime='application/x-executable; charset=binary' or mime='application/x-object; charset=binary' or mime='application/x-sharedlib; charset=binary') order by score DESC;" | tail -n+3 | head -n-2 | sed -e 's/^ /\./')
echo "Extracting library links......"
tar xf ${FIRMWARE_DIR}/${IID}.tar.gz -C ${BIN_DIR} $(psql -U firmadyne -d firmware -c "select filename from object_to_image where iid=${IID} and regular_file='f';" | tail -n+3 | head -n-2 | sed -e 's/^ /\./' | grep 'lib')

# get the firmware architecture
ARCH=$(psql -U firmadyne -d firmware -c "select arch from image where id=${IID};" | head -3 | tail -1 | sed -e 's/ //g')
[[ "${ARCH}" = "armel" ]] && ARCH=arm
[[ "${ARCH}" = "mipseb" ]] && ARCH=mips
AFL_INST_LIBS=1
AFL_EXIT_WHEN_DONE=1
AFL_NO_AFFINITY=0
AFL_PATH=$(which afl-qemu-trace)-${ARCH}

if [[ -z "${AFL_PATH}" ]]; then
	echo "Unknown architecture: ${ARCH}"
	exit 1
fi

trap "" SIGINT
trap "trap '' SIGTERM; kill -TERM 0; exit 0" SIGHUP SIGQUIT SIGTERM

# fuzz the binaries
for target in $(psql -U firmadyne -d firmware -c "select filename from object_to_image where iid=${IID} and score>0 and mime='application/x-executable; charset=binary' order by score DESC;" | tail -n+3 | head -n-2 | sed -e "s/^ \///")
do
	echo -e "\nfuzzing ${target}..."
	if [[ ! -d ${OUT_DIR}/${target} ]]; then
		mkdir -p ${OUT_DIR}/${target}
		AFL_PATH=${AFL_PATH} afl-fuzz -Q -M master -m ${MEMORY} -i /usr/share/afl/testcases/others/text -o ${OUT_DIR}/${target} -L ${BIN_DIR}/ ${BIN_DIR}/${target} &> /dev/null &
		AFL_PATH=${AFL_PATH} afl-fuzz -Q -S slave1 -m ${MEMORY} -i /usr/share/afl/testcases/others/text -o ${OUT_DIR}/${target} -L ${BIN_DIR}/ ${BIN_DIR}/${target} &> /dev/null &
		AFL_PATH=${AFL_PATH} afl-fuzz -Q -S slave2 -m ${MEMORY} -i /usr/share/afl/testcases/others/text -o ${OUT_DIR}/${target} -L ${BIN_DIR}/ ${BIN_DIR}/${target} &> /dev/null &
		AFL_PATH=${AFL_PATH} afl-fuzz -Q -S slave3 -m ${MEMORY} -i /usr/share/afl/testcases/others/text -o ${OUT_DIR}/${target} -L ${BIN_DIR}/ ${BIN_DIR}/${target} &> /dev/null &
	else
		AFL_PATH=${AFL_PATH} afl-fuzz -Q -M master -m ${MEMORY} -i - -o ${OUT_DIR}/${target} -L ${BIN_DIR}/ ${BIN_DIR}/${target} &> /dev/null &
		AFL_PATH=${AFL_PATH} afl-fuzz -Q -S slave1 -m ${MEMORY} -i - -o ${OUT_DIR}/${target} -L ${BIN_DIR}/ ${BIN_DIR}/${target} &> /dev/null &
		AFL_PATH=${AFL_PATH} afl-fuzz -Q -S slave2 -m ${MEMORY} -i - -o ${OUT_DIR}/${target} -L ${BIN_DIR}/ ${BIN_DIR}/${target} &> /dev/null &
		AFL_PATH=${AFL_PATH} afl-fuzz -Q -S slave3 -m ${MEMORY} -i - -o ${OUT_DIR}/${target} -L ${BIN_DIR}/ ${BIN_DIR}/${target} &> /dev/null &
	fi
	wait
done

