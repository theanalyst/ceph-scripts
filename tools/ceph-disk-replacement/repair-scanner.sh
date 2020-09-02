#!/bin/bash

#usage ./repair-scanner.sh <clustername> 


MONITORING_HOST="filer-carbon.cern.ch"
MONITORING_PORT="2003"
METRIC_PREFIX="ceph-repairs"

for i in `ceph osd tree | grep host | awk '{print $4}'`; 
do
  drain=`ssh -oStrictHostKeyChecking=no $i ls /tmp/log.drain.* 2> /dev/null`;
  replt=`ssh -oStrictHostKeyChecking=no $i ls /tmp/log.prepare.* 2> /dev/null`;

  if [ ! -z $drain ];
  then
    for j in `echo $drain`;
    do
      echo "[draining] $i $j"
    done
  fi

  if [ ! -z $replt ];
  then
    for j in `echo $replt`;
    do
      echo "[replacing] $i $j"
    done
  fi
done
