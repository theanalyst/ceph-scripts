#!/bin/bash

for i in `host s3.cern.ch | grep -Eo "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+"`; 
do
  JOBN=`ssh -T $i < ./s3-radosgw-whoami.sh`
  HOST=`ssh $i facter -p "hostname"`

  if [ $JOBN ];
  then
    echo $JOBN" "$HOST
  else
    echo "spare "$HOST
  fi
done

