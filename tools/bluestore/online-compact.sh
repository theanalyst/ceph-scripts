#!/bin/bash

dry_run=0

while getopts 'n' opt; do
    case "$opt" in
        n) dry_run=1 ;;
        *) echo 'error in command line parsing' >&2
           exit 1
    esac
done

if [ "$dry_run" -eq 1 ]; then
    cmd=echo
else
    cmd=''
fi

for OSD in /var/lib/ceph/osd/ceph-*/whoami;
do
  ID=`cat ${OSD}`
  BEFORE=$(ceph daemon osd.$ID perf dump bluefs | jq .bluefs.db_used_bytes)
  echo osd.$ID db_used_bytes before: $BEFORE
  $cmd ceph daemon osd.$ID compact
  $cmd ceph daemon osd.$ID compact
  AFTER=$(ceph daemon osd.$ID perf dump bluefs | jq .bluefs.db_used_bytes)
  echo osd.$ID db_used_bytes after: $AFTER
done
