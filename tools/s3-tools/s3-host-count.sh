#!/usr/bin/env bash


fping s3.cern.ch > /dev/null;
RETVAL=$?;

if [ $RETVAL -ne 0 ];
then
  echo " "
else
  HOSTCOUNT=`host s3.cern.ch | grep "has address" | wc -l`;
 
  if [ $HOSTCOUNT -le 4 ];
  then
    /afs/cern.ch/user/j/jcollet/.local/bin/telegram-send "Only ${HOSTCOUNT} hosts in s3.cern.ch"
  fi
fi

