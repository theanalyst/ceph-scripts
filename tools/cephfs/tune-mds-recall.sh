#!/bin/bash

# Usage: $0 <X>
#
# where X is a factor to scale the default mds recall options

set -e
set -x

[ "$1" ] || exit

H=$(hostname -s)
X=$1

echo Scaling MDS Recall by ${X}x
ceph tell mds.* injectargs -- --mds_recall_max_decay_threshold $((X*16*1024)) --mds_recall_max_caps $((X*5000)) --mds_recall_global_max_decay_threshold $((X*64*1024)) --mds_recall_warning_threshold $((X*32*1024)) --mds_cache_trim_threshold $((X*64*1024))

# defaults below
#ceph daemon mds.$H config set mds_cache_memory_limit $((4*1024*1024*1024))
#ceph daemon mds.$H config set mds_max_caps_per_client 1048576
