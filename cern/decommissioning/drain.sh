#!/bin/bash

set -e

ceph osd set norebalance

# drain the host
ceph osd crush reweight-subtree `hostname -s` 0

# Use upmap to minimize PG movement unrelated to this box
/root/ceph-scripts/tools/upmap/upmap-remapped.py | sh
/root/ceph-scripts/tools/upmap/upmap-remapped.py | grep -v rm | sh

ceph osd unset norebalance
