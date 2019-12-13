#!/bin/bash

#usage ./no-osd-left-behind.sh <cephcluster>

OUTFILE="s3-accounting-`date '+%F'`.log"

echo -n "" > $OUTFILE

for i in `ceph osd tree | grep host | grep -Eo "p.*"`; 
do 
  ssh -oStrictHostKeyChecking=no $i ceph-scripts/tools/ceph-disk-replacement/list-available-drives.sh  >> ${OUTFILE}
done


cat $OUTFILE | jq '. | {path: .path, hostname: .hostname} | select(.path)'
s3cmd put $OUTFILE s3://ceph-`echo $1`/








#rm OUTFILE



#while [[ $# -gt 0 ]]
#do
#    key="$1"
#
#    case "$key" in
#        -s) 
#        shift; 
#        SUMMARY=1;
#        ;;
#
#    esac
#done
#
#echo "Scanning ceph/`cat /etc/motd | grep -Eo "ceph/.*/mon" | cut -d/ -f2`"
#
#for i in `ceph osd tree down | grep -E "host" | cut -d"p" -f2`; 
#do 
#  ssh p"$i" /root/ceph-scripts/tools/ceph-disk-replacement/diagnose.sh; 
#done
#
#
#if [[ ! -z $SUMMARY ]];
#then
#    FAILEDOSD=`ceph osd tree down | grep osd | wc -l`;
#
#    echo "Summary for ceph/`cat /etc/motd | grep -Eo "ceph/.*/mon" | cut -d/ -f2`:"
#    echo "Number of down OSDs: $FAILEDOSD"
#fi
