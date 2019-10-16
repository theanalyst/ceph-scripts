#! /bin/bash


for i in `ceph-volume inventory | grep -E "/dev/sd[a=z]?[a-z]"`;
do
 echo "-> $i"
done

