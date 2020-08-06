#! /bin/bash


devicelist=`ceph device ls | grep -E "osd.[0-9]+ osd.[0-9]+" | grep SAM` 


echo "$devicelist" | while read -r line; 
do
    partcount=`echo -n $line | awk '{print gsub("osd", "")}'`
    if [ $partcount -ne 6 ];
    then
        host=`echo $line | grep -Eo "p[0-9a-z]+"`
        if [ ! -z $host ]; then
            echo "Checking host: $host"
            echo "unused partition(s): "
            ssh -n $host /root/ceph-scripts/tools/ceph-disk-replacement/scan.sh
            echo "misconfigured osds" 
            ssh -n $host lvs -odevices,tags | grep -v db_device | grep -Eo "osd_id=[0-9]+" | grep -Eo "[0-9]+"
        fi
    echo ""
    fi
done

#ceph device ls | grep -E "osd.[0-9]+ osd.[0-9]+" | while read line; do echo -n "$line "; echo -n $line | awk '{print gsub("osd", "")}'; done  | grep -v 5$ | sort -k2r  | grep INT
#ceph device ls | grep -E "osd.[0-9]+ osd.[0-9]+" | while read line; do echo -n "$line "; echo -n $line | awk '{print gsub("osd", "")}'; done   | grep -v 6$ | sort -k2r  | grep SAMS | while read dline; do host=`echo $dline | grep -Eo "p[0-9a-z]+"`; if [ $host ]; then echo "ssh $host /root/ceph-scripts/tools/ceph-disk-replacement/scan.sh"; fi;  done | sort | uniq
