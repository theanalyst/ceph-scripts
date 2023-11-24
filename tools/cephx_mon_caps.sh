#!/bin/bash

DEFAULT_MON='allow r'
usage="cephx_mon_caps.sh <entity>

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


if [ x"$mon" == x"null" ]; then
  echo
  echo "DEBUG: Capabilities on mon not found."
  echo "DEBUG: Adding default '$DEFAULT_MON' for mon"

  echo "Check command and fix mon caps with:"
  echo "  ceph auth caps $entity \
mon '$DEFAULT_MON' \
osd '${osd}' \
mds '${mds}'"
else
  echo
  echo "DEBUG: $entity seems to have good capabilities"
fi

