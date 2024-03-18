#!/bin/bash


INODE=$1

if [ x"$INODE" == x"" ];
then
  echo "No inode provided."
fi

# Find the path from the inode
path=$(ceph daemon mds.`hostname -s` dump inode $INODE | jq -r .path | cut -d '/' -f 4)
echo "  Debug -- path: $path"

# Echo a command to evict all the clients mounting that path
echo $client_ls | jq -r '.[] | "\(.id), \(.client_metadata.root)"' | grep $path | cut -d ',' -f 1 | xargs -i echo ceph tell mds.* client evict id={}

# Dump the list of clients
client_ls=$(ceph daemon mds.`hostname -s` client ls)
output_file="find_and_evict_clientls_$INODE_$(date +%s)"
echo "  Debug -- writing client_ls output to $output_file"
echo $client_ls > $output_file

