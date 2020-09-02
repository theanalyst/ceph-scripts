#!/bin/bash

cluster=`facter hostgroup_1`


for disk in `ls /tmp/log.drain.*`;
do
  echo "cephrepairs.${cluster}.`echo $i | sed -e 's/\/tmp\/log.//' -e 's/.cern.ch//'` 1 `date +%s`"
  echo "cephrepairs.${cluster}.`echo $i | sed -e 's/\/tmp\/log.//' -e 's/.cern.ch//'` 1 `date +%s`" | nc filer-carbon.cern.ch 2003;
done
