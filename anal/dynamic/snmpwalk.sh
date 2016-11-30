#!/bin/sh

TARGET_IP=$1

snmpwalk -v2c -c public ${TARGET_IP} .iso &> snmp.public.txt
snmpwalk -v2c -c private ${TARGET_IP} .iso &> snmp.private.txt

echo "Dumped to snmp.public.txt and snmp.private.txt!"
