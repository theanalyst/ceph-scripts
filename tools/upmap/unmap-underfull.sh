#!/bin/bash

UNDERFULL=`ceph osd df | grep hdd | grep 1.00000 | sort -k8 -n | head -n4 | awk '{print $1}'`

for osd in $UNDERFULL
do
#  echo Unmapping $osd ...
  ceph osd dump | grep pg_upmap_items | egrep "\b${osd}\b" | awk '{print "ceph osd rm-pg-upmap-items", $2, "&"}' | sort -R | head -n4
done
