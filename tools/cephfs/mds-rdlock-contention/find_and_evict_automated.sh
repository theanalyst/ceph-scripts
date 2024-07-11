#!/bin/bash

hostname=$(hostname -s)
logfile="/var/log/ceph/ceph-mds.$hostname.log"

dump_path="/root/find_and_evict_debug"
mkdir -p $dump_path
now=$(date +%s)

# Debugging purposes
# inodes=$(zcat /var/log/ceph/ceph-mds.cephcpu21-0c370531cf.log-20240319.gz | grep "failed to rdlock" | awk '{print $18}' | cut -d '/' -f 1 | sort | uniq | grep "^#0x" | tr -d '#')

inodes=$(tail -n 50 $logfile | grep "failed to rdlock" | awk '{print $18}' | cut -d '/' -f 1 | sort | uniq | grep "^#0x" | tr -d '#')
for inode in $inodes
do
  # Find the path from the inode
  dump_inode=$(ceph daemon mds.`hostname -s` dump inode $inode)
  fullpath=$(echo $dump_inode | jq -r .path)
  sharepath=$(echo $dump_inode | jq -r .path | cut -d '/' -f 4)

  # Echo a command to evict all the clients mounting that path
  client_ls=$(ceph daemon mds.`hostname -s` client ls)
  clients=$(echo $client_ls | jq -r '.[] | "\(.id), \(.client_metadata.root)"' | grep $sharepath | cut -d ',' -f 1)
  for cl in $clients
  do
    ceph tell mds.* client evict id=$cl;
  done

  # Dump the inode description from MDS
  dump_inode_file="$dump_path/$inode-dumpinode-$now"
  echo $dump_inode > $dump_inode_file

  # Dump the list of clients
  clientls_file="$dump_path/$inode-clientls-$now"
  echo $client_ls > $clientls_file

  echo
  echo
done
