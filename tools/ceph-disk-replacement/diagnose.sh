#! /bin/bash 

PATIENT=`echo $HOSTNAME | cut -d"." -f1 `

echo "Diagnosing patient: $PATIENT"

echo "Generating ill osd list"
for i in `ceph osd tree down | awk -v awkhost=$PATIENT 'BEGIN { out=0 } { if($0 ~ /rack/) {out=0} if(out) {print $0;} if($0 ~ awkhost) {out=1}; }' | grep -Eo "osd\.[0-9]+" | tr -d "[a-z\.]"`;
do
  OSD=`echo "osd.$i"`;
  DEV=""
  for i in `lvs -o +devices,tags | grep -E "osd_id=$i" | grep -Eo "/dev/sd[a-z]+"`; 
  do 
    DEV=`echo "$DEV $i"`; 
  done

  if [[ -z $DEV ]];
  then
    echo "No device found"
    for i in `lsscsi | grep -Eo "/dev/sd[c-z]|/dev/sd[a-z][a-z]"`; do lvs -o +devices,tags | grep "$i" -q; if [[ $? -eq 1 ]]; then DEV=`echo $DEV $i`; fi; done
    echo "-> $DEV seems unattached, replacement in progress?"
  fi

  for i in `echo $DEV | grep -Eo "sd[a-z]+"`;
  do
    dmesg -T | grep $i | grep -qi Error;
    if [[ $? -eq 0 ]];
    then
      echo "- $OSD: bad drive $i"
    fi
  done
done

echo " "
