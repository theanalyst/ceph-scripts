#!/bin/bash

#usage ./repair-scanner.sh <clustername> 


MONITORING_HOST="filer-carbon.cern.ch"
MONITORING_PORT="2003"
METRIC_PREFIX="ceph-repairs"

for i in `ceph osd tree | grep host | awk '{print $4}'`; 
do  
  echo -n "$i "; 
  drain=`ssh $i ls /tmp/log.drain.*`;
  replt=`ssh $i ls /tmp/log.prepare.*`;

  if [ $drain -ne "" ];
  then
    for j in `echo $drain`;
    do
      echo "[draining] $i $j"
    done
  fi

  if [ $replt -ne "" ];
  then
    for j in `echo $replt`;
    do
      echo "[replacing] $i $j"
    done
  fi
done
