#!/bin/bash
CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"


cp /usr/lib/python3.6/site-packages/ceph_volume/util/device.py /usr/lib/python3.6/site-packages/ceph_volume/util/device.py.backup
cp $CWD/device.py /usr/lib/python3.6/site-packages/ceph_volume/util/device.py

cp $CWD/lsmdisk.py /usr/lib/python3.6/site-packages/ceph_volume/util/lsmdisk.py

cp /usr/lib/python3.6/site-packages/ceph_volume/api/lvm.py /usr/lib/python3.6/site-packages/ceph_volume/api/lvm.py.backup
cp $CWD/lvm.py /usr/lib/python3.6/site-packages/ceph_volume/api/lvm.py
