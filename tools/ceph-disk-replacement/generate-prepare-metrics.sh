#!/bin/bash

cluster=`/opt/puppetlabs/bin/facter hostgroup_1`


for disk in `ls /tmp/log.prepare.*`;
do
  echo "cephrepairs.${cluster}.`echo $disk | sed -e 's/\/tmp\/log.//' -e 's/.cern.ch//'` 1 `date +%s`" | nc filer-carbon.cern.ch 2003;
done