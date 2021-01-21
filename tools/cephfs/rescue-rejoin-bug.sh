#!/bin/bash

set -e

RANK=$1

if [ -z "$RANK" ]
then
    echo "Usage: $0 <rank> [--rescue]"
    exit 1
fi

RESCUE=$2

echo Current FS status:
ceph status | grep mds:

ceph status -f json > /tmp/status.json
echo Checking status of rank $RANK
NAME=`cat /tmp/status.json | jq ".fsmap.by_rank[$RANK] | .name"`
NAME=`cat /tmp/status.json | jq ".fsmap.by_rank[$RANK] | .status"`

echo .. running on $NAME with status $STATUS

# exit if status is active
echo $STATUS | grep -q active 

echo Checking openfiles objects...

for i in {0..9}
do
    F="mds${RANK}_openfiles.${i}"
    rados -p cephfs_metadata stat $F && (
        echo -n "$F exists with size:"
        rados -p cephfs_metadata listomapkeys | wc -l
        if [ -z "$RESCUE" ]
        then
            echo "Use --rescue to remove object named $F"
        else
            echo "rados -p cephfs_metadata_pool rm $F"
        fi
    )
done
