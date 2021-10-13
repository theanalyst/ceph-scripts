#!/bin/bash

ceph-volume lvm batch /dev/sd[a-z] /dev/sda[a-v] /dev/sda[y-z] /dev/sdba /dev/sdbb
