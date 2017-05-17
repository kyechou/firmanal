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

if [[ $# -lt 1 ]]; then
    echo "Usage: inferNetwork.sh <image ID> [<architecture>]"
    exit 1
fi

if check_number $1; then
    echo "Usage: inferNetwork.sh <image ID> [<architecture>]"
    exit 1
fi
IID=${1}

if [ $# -gt 1 ]; then
    if check_arch "${2}"; then
        echo "Error: Invalid architecture!"
        exit 1
    fi

    ARCH=${2}
else
    echo -n "Querying database for architecture... "
    ARCH=$(psql -d firmware -U firmadyne -h 127.0.0.1 -t -q -c "SELECT arch from image WHERE id=${1};")
    ARCH="${ARCH#"${ARCH%%[![:space:]]*}"}"
    echo "${ARCH}"
    if [ -z "${ARCH}" ]; then
        echo "Error: Unable to lookup architecture. Please specify {armel,mipseb,mipsel} as the second argument!"
        exit 1
    fi
fi

echo "Running firmware ${IID}: terminating after 60 secs..."
timeout --preserve-status --signal SIGINT 60 "${VM_SCRIPT_DIR}/run.${ARCH}.sh" "${IID}"
sleep 1

echo "Inferring network..."
"${VM_SCRIPT_DIR}/makeNetwork.py" -i "${IID}" -q -o -a "${ARCH}" -S "${VM_DIR}"

echo "Done!"
