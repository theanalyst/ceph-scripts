#!/bin/bash

unset OS_PROJECT_ID;
unset OS_TENANT_ID;
unset OS_TENANT_NAME;
export OS_PROJECT_NAME="IT Ceph Ironic";


bnl='1_baremetal_node_list'
ss='2_server_show'
ad='3_ai_dump'

#
# Goal
#   Identify mismatching information between LANDB and Openstack Ironic
#
# Why
#   In August 2022, we have identified a mismatch between two hosts in Nethub:
#     - cephnethub-data22-7d955fdec8, DL8822375-E386345X1C02693-B, HB05
#     - cephnethub-data22-0fc58cffb3, DL8822375-E386345X1C02692-A, HB06
#   The mismatch originated when the Repair team updated information in LanDB to fix an error
#   at the time of installation. The new information in LanDB is NOT reflected in OpenStack Ironic.
#   As a result, we ended up reinstalling the wrong box via `ai-*` commands :/
#   There are no known fixes at the moment but deleting and recreating the affected instances.
#
# How it works
#  1. OpenStack: Get the list of baremetal nodes from Ironic [1]. It contains:
#     - The node serial number
#     - The internal OpenStack UUID of the instance
#  2. OpenStack: Get the instance name from the instance UUID
#  3. LanDB: Get the serial number from the hostname (`ai-dump`)
#  4. Verify the two serial numbers match. If they don't, you have a problem. 
#
# [1]:
#    - You need to be in the right Openstack project
#    - Openstack has to allow listing baremetal nodes for that project (it is not the default)
###


## Get the list of baremetal nodes
echo "Dumping the list of active baremetal nodes for project \"$OS_PROJECT_NAME\""
openstack baremetal node list \
	--provision-state "active" \
	--column "Name" \
	--column "Instance UUID" \
	-f csv --quote none \
	> $bnl


## Get the Openstack instance name from the Instance UUID
echo "Resolving Openstack Instance UUIDs to names - This may take a while..."

echo "" > $ss
for line in $(cat $bnl | tail -n+2)
do
  uuid=$(echo $line | cut -d ',' -f 2)
  os_name=$(openstack server show -c name -f value $uuid)
  if [ $? -ne 0 ]; then
    echo "  $uuid - Error from OpenStack. Dropping this node and continuing..."
  fi
  echo $line","$os_name >> $ss
done


## Get the serial number from the hostname through ai-dump
echo "Resolving the instance name to its serial number querying LanDB - This may take another while..."

echo "" > $ad
for line in $(cat $ss)
do
  name=$(echo $line | cut -d ',' -f 3)
  ai_dump=$(ai-dump $name --facts landb_serial_number --json 2>/dev/null)
  if [ $? -ne 0 ]; then
    echo "  $name - Error from LanDB. Dropping this node and continuing..."
    continue
  fi
  serial=$(echo $ai_dump | jq -r .[].landb_serial_number | tr '[:upper:]' '[:lower:]')
  echo $line","$serial >> $ad
done


## Verify the two serial numbers match
echo "Verifying the serial numbers match"
count=0
for line in $(cat $ad)
do
  os_serial=$(echo $line | cut -d ',' -f 1)
  landb_serial=$(echo $line | cut -d ',' -f 4)
  if [ "$os_serial" != "$landb_serial" ];
  then
    echo "  Mismatch on $line"
    count=$(($count+1))
  fi
done

if [ $count -eq 0 ];
then
  echo "No mismatches on serial numbers found."
fi

