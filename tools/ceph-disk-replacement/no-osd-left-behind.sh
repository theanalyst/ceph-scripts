#!/bin/bash

#usage ./no-osd-left-behind.sh <cephcluster>


# make sure the cluster runs nautilus
ret=`ceph --cluster=$1 version | awk '{ print $3 }' | awk -F . '{ if( $1 >= 14) { print $0 } }'`
if [[ -z $ret ]];
then
  echo "Requires at least ceph nautilus"
  exit -1
fi



# Check for down osds
for i in `ceph --cluster $1 osd tree down | grep -Eo "osd.[0-9]+"`; 
do
#    # Checking each drives of the down osds
    echo "Checking $i"
    for j in `ceph --cluster $1 device ls-by-daemon --format=json-pretty $i | jq -c '.[] | .location[] | { host: .host, dev: .dev}'`;
    do
        echo $j
    done 
done
    
