#!/bin/bash


INODE=$1

if [ x"$INODE" == x"" ];
then
  echo "No inode provided."
fi


# Find the path from the inode
dump_inode=$(ceph daemon mds.`hostname -s` dump inode $INODE)
fullpath=$(echo $dump_inode | jq -r .path)
sharepath=$(echo $dump_inode | jq -r .path | cut -d '/' -f 4)

# Echo a command to evict all the clients mounting that path
client_ls=$(ceph daemon mds.`hostname -s` client ls)
echo $client_ls | jq -r '.[] | "\(.id), \(.client_metadata.root)"' | grep $sharepath | cut -d ',' -f 1 | xargs -i echo ceph tell mds.* client evict id={}

# Dump the inode description from MDS
dump_inode_file="$INODE-dumpinode-$(date +%s)"
echo "  Debug -- writing dump_inode output to $dump_inode_file"
echo $dump_inode > $dump_inode_file

# Dump the list of clients
output_file="$INODE-clientls-$(date +%s)"
echo "  Debug -- writing client_ls output to $output_file"
echo $client_ls > $output_file

# Dump the fullpath of the stuck operation
echo "  Debug -- fullpath: $fullpath"
