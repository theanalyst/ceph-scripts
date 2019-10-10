#!/bin/bash

while [[ $# -gt 0 ]]
do
    key="$1"

    case "$key" in
        -s) 
        shift; 
        SUMMARY=1;
        ;;

    esac
done


for i in `ceph osd tree down | grep -E "host" | cut -d"p" -f2`; 
do 
  ssh p"$i" /root/ceph-scripts/tools/ceph-disk-replacement/diagnose.sh; 
done


if [[ ! -z $SUMMARY ]];
then
    FAILEDOSD=`ceph osd tree down | grep osd | wc -l`;

    echo "SUMMARY:"
    echo "Number of down OSD: $FAILEDOSD"
fi
