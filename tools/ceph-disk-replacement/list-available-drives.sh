#! /bin/bash

ceph-volume inventory | awk '{ if( $4 == "True" && $5 == "True") print $0}' | grep -v "/dev/m" 
