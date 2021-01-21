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
NAME=`cat /tmp/status.json | jq -r ".fsmap.by_rank[$RANK] | .name"`
STATUS=`cat /tmp/status.json | jq -r ".fsmap.by_rank[$RANK] | .status"`

echo Rank $RANK: running on $NAME with status $STATUS

echo
echo Checking openfiles objects...
echo

for i in {0..9}
do
    F="mds${RANK}_openfiles.${i}"
    rados -p cephfs_metadata stat $F &> /dev/null && (
        echo -n "$F exists with size: "
        rados -p cephfs_metadata listomapkeys $F | wc -l
        if [ -z "$RESCUE" ]
        then
            echo "  use --rescue to remove object named $F"
        else
            # exit if status is active
            if echo $STATUS | grep -q active
            then
                echo ERROR: rank $RANK is active, aborting...
                exit 1
            else
                echo "rados -p cephfs_metadata rm $F"
            fi
        fi
    )
    echo
done
