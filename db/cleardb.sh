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

sudo systemctl stop postgresql.service
sudo rm -rf /var/lib/postgres/data
sudo mkdir /var/lib/postgres/data
sudo chmod -R 700 /var/lib/postgres/data
sudo chown -R postgres:postgres /var/lib/postgres/data
sudo -u postgres initdb --locale $LANG -E UTF-8 -D '/var/lib/postgres/data'
sudo systemctl start postgresql.service
sudo -u postgres createuser firmadyne -s
sudo -u postgres createdb -O firmadyne -U firmadyne firmware
sudo -u postgres psql -d firmware < ${DB_DIR}/schema

echo "Database cleared!"
