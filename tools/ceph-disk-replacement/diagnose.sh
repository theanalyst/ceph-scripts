#! /bin/bash 

PATIENT=`echo $HOSTNAME | cut -d"." -f1 `

echo "Diagnosing patient: $PATIENT"
for i in `ceph osd tree down | awk -v awkhost=$PATIENT 'BEGIN { out=0 } { if($0 ~ /host/ && out) {out=0} if(out) {print $0;} if($0 ~ awkhost) {out=1}; }' | grep -Eo "osd\.[0-9]+" | tr -d "[a-z\.]"`;
do
  OSD=`echo "osd.$i"`;
  DMNSTATUS=`systemctl status ceph-osd@$i | grep -E "Active:" | sed -e 's/Active: //'`;
  IOERROR=`systemctl status ceph-osd@$i | grep -Eo "Input/output error" | uniq`
  DEV=""
  for i in `lvs -o +devices,tags | grep -E "osd_id=$i" | grep -Eo "/dev/sd[a-z]+"`; 
  do 
    DEV=`echo "$DEV $i"`; 
  done

  if [[ -z $DEV ]];
  then
#DEV=""; i=204; for i in `lsscsi | grep -Eo "/dev/sd[c-z]|/dev/sd[a-z][a-z]"`; do lvs -o +devices,tags | grep "$i" -q; if [[ $? -eq 1 ]]; then blkid | grep "ceph data" | grep -q -E "$DEV"; if [[ $? -eq 1 ]]; then  DEV=`echo $DEV $i`; fi; fi; done; echo $DEV

    for i in `lsscsi | grep -v INTEL | grep -Eo "/dev/sd[c-z]|/dev/sd[a-z][a-z]"`; 
    do 
      lvs -o +devices,tags | grep "$i" -q; 
      if [[ $? -eq 1 ]]; 
      then
        blkid | grep "ceph" | grep -q -E "$i";
        if [[ $? -eq 1 ]];
        then
          DEV=`echo $DEV $i`;
        fi;
      fi;
    done
    echo "$OSD: $DEV seems unattached, replacement in progress?"
  fi

  for i in `echo $DEV | grep -Eo "sd[a-z]+"`;
  do
    dmesg -T | grep $i | grep -qi Error;
    if [[ $? -eq 0 ]];
    then
      echo "$OSD: bad drive $i (Power_On_Hours: `smartctl -a /dev/$i | grep -i Power_on_hours | awk '{ print $10; }'`)"
    fi
  done
  
  echo "$OSD: daemon is $DMNSTATUS";
  if [[ -z $IOERROR ]];
  then 
    echo "$OSD: I/O errors";
  fi
done
echo "--"
