#! /bin/bash

fping s3.cern.ch > /dev/null;
RETVAL=$?;

if [ $RETVAL -ne 0 ];
then
  STATUS="offline"
else
  s3cmd ls > /dev/null;
  s3retval=$?
  
  hostcount=`host s3.cern.ch | grep "has address" | wc -l`;
  
  if [ $s3retval -ne 0 ]; then
    /afs/cern.ch/user/j/jcollet/.local/bin/telegram-send "CERN Ceph/S3 service seems down (${hostcount} hosts)" 
  fi
fi 


