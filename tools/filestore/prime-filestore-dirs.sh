#!/bin/bash

# This script is used to create a few thousand new objects in a
# given pool. It helps to push OSD FileStore dirs over a split
# threshold before a user op would do so.

usage() {
    cat <<EOM
    Usage:
    $(basename $0) POOLNAME

EOM
    exit 0
}

[ -z $1 ] && { usage; }

POOL=$1

ulimit -n100000

rados bench -p ${POOL} 120 write -b 4096
