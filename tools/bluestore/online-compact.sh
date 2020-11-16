#!/bin/bash

for OSD in /var/lib/ceph/osd/ceph-*/whoami;
do
  ID=`cat ${OSD}`
  echo osd.$ID slow_used_bytes before: $(ceph daemon osd.$ID perf dump bluefs | jq .bluefs.slow_used_bytes)
  ceph daemon osd.$ID compact
  ceph daemon osd.$ID compact
  echo osd.$ID slow_used_bytes after: $(ceph daemon osd.$ID perf dump bluefs | jq .bluefs.slow_used_bytes)
done
