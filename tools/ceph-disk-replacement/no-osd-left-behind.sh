#!/bin/bash

#usage ./no-osd-left-behind.sh <cephcluster>


# make sure the cluster runs nautilus
ret=`ceph --cluster=$1 version | awk '{ print $3 }' | awk -F . '{ if( $1 >= 14) { print $0 } }'`
if [[ -z $ret ]];
then
  echo "Requires at least ceph nautilus"
  exit -1
fi

echo "Generating report for ceph-$1"


# Check for down osds
for i in `ceph --cluster $1 osd tree down | grep -Eo "osd.[0-9]+"`;
do
#    # Checking each drives of the down osds
    echo "Checking status of $i (down)"
    for j in `ceph --cluster $1 device ls-by-daemon --format=json-pretty $i | jq -c '.[] | .location[] | { host: .host, dev: .dev}'`;
    do
        target_host=`echo $j  | jq -r -c '.host'`
        target_drive=`echo $j | jq -r -c '.dev'`

        dmesg_report=`ssh -oStrictHostKeyChecking=no $target_host dmesg -T | grep $target_drive | grep "medium error" | tail -1`
        if [[ ! -z $dmesg_report ]];
        then
            echo "[$target_host:$target_drive] Latest dmesg error:"
            echo "[$target_host:$target_drive]       $dmesg_report" 
        fi

        hist_report=`ssh -oStrictHostKeyChecking=no $target_host cat /root/.bash_history | grep -E "\-\-dev \/dev\/$target_drive"`
        if [[ ! -z $hist_report ]];
        then
            echo "[$target_host:$target_drive] Plausible repair in progress..."
            diskreport=`ssh -oStrictHostKeyChecking=no $target_host smartctl -a /dev/$target_drive -j`;
            if [ `echo $diskreport | grep "No such device" -c` -eq 0 ];
            then
                echo "[$target_host:$target_drive] $target_drive has `echo $diskreport | jq '.power_on_time | .[]' ` power on hours on the clock"
            else
                echo "[$target_host:$target_drive] Drive appears to be missing"
            fi
            echo "[$target_host:$target_drive] $hist_report"
        fi

        if [[ -z $hist_report && -z $dmesg_report ]];
        then
          echo "[$target_host:$target_drive] Cannot determine the drive's status, will require manual investigation"
        fi
    done
done

