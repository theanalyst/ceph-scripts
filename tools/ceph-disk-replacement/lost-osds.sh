#! /bin/bash


AVAILDRIVES=`ceph-volume inventory | awk '{ if( $1 ~ /\/dev\/sd[a-z]?[a-z]/ ) { if ( $5 ~ /True/ ) { if ( $4 ~ /True/ ) { print $0" HDD"} else { print $0" SSD"}} } }'`
echo $AVAILDRIVES
