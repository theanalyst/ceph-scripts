#!/bin/bash

cluster=`/opt/puppetlabs/bin/facter hostgroup_1`


echo "cephrepairs.${cluster}.drain.`hostname -s` `ls /root/log.${cluster}.drain.* 2> /dev/null | wc -l` `date +%s`" | nc filer-carbon.cern.ch 2003;
echo "cephrepairs.${cluster}.prepare.`hostname -s` `ls /root/log.${cluster}.prepare.* 2> /dev/null | wc -l` `date +%s`" | nc filer-carbon.cern.ch 2003;


echo "cephrepairs.${cluster}.drain.`hostname -s` `ls /root/log.${cluster}.drain.* 2> /dev/null | wc -l` `date +%s`" | nc metrictank-carbon.cern.ch 2003;
echo "cephrepairs.${cluster}.prepare.`hostname -s` `ls /root/log.${cluster}.prepare.* 2> /dev/null | wc -l` `date +%s`" | nc metrictank-carbon.cern.ch 2003;
