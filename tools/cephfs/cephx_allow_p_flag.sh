#!/bin/bash

usage="cephx_allow_p_flag.sh <entity>

where:
  <entity> is the name of the ceph user (e.g., client.myself)
"

entity=$1
if [ x"$entity" == x"" ];
then
  echo
  echo "ERROR: No entity provided"
  echo "$usage"
  exit
fi

# Get existing capabilities
caps=$(ceph auth get $entity -f json 2>/dev/null | jq .[].'caps')
mon=$(echo $caps | jq -r .'mon')
osd=$(echo $caps | jq -r .'osd')
mds=$(echo $caps | jq -r .'mds')

echo "DEBUG: Existing capabilities for $entity"
echo $caps

mds_with_pflag=$(echo ${mds} | sed 's/allow rw/allow rwp/')
echo "Check command and add 'p flag' cap with:"
echo "  ceph auth caps $entity \
mon '${mon}' \
osd '${osd}' \
mds '${mds_with_pflag}'"

