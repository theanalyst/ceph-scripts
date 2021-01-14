#!/bin/bash

rm -f /usr/lib/python3.6/site-packages/ceph_volume/util/device.py
rm -f /usr/lib/python3.6/site-packages/ceph_volume/util/lsmdisk.py 
rm -f /usr/lib/python3.6/site-packages/ceph_volume/api/lvm.py

mv /usr/lib/python3.6/site-packages/ceph_volume/util/device.py.backup /usr/lib/python3.6/site-packages/ceph_volume/util/device.py
mv /usr/lib/python3.6/site-packages/ceph_volume/api/lvm.py.backup /usr/lib/python3.6/site-packages/ceph_volume/api/lvm.py
