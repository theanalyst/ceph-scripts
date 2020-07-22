#!/bin/bash

## Ceph Version check
ret=`ceph -v | awk '{ print $3 }' | awk -F . '{ if( $1 >= 14) { print $0 } }'`

if [[ -z $ret ]];
then
  echo "Requires at least ceph nautilus"
  exit -1;
fi


if [[ `roger show $HOSTNAME  | jq .[].appstate | tr -d "\""` == "intervention" ]];
then
  echo "Operation cannot be performed. Machine currently in `roger show $HOSTNAME | jq '.[].appstate' | grep -Eo [a-Z]+` state (updated by: `roger show $HOSTNAME | jq '.[].updated_by'`) with the following message: `roger show $HOSTNAME | jq '.[].message'`";
  if [[ `roger show $HOSTNAME  | jq .[].expires | tr -d "\""` ]];
  then
    echo "Disk replacement operations impossible until `roger show $HOSTNAME  | jq .[].expires`";
  else
    echo "No end-of-intervention date specified, contact ceph-admins";
  fi
  exit
fi


if [[ `cat /etc/motd | grep hostgroup | grep -Eo "ceph/[a-Z0-9/]+" | grep -c erin` -eq 1 ]];
then
  CASTOR=1
fi


if [[ `lsscsi  | grep -v encl | grep -v INT | wc -l` -gt 40 && `cat /etc/motd | grep hostgroup | grep -Eo "ceph/[a-Z0-9/]+" | grep -c gabe` -eq 1  ]]
then
  CASTOR=1
fi


INITSTATE=`ceph health`
FORCEMODE=0;
VERBOSE=0
BLUESTORE=0;

while [[ $# -gt 0 ]]
do
  key="$1"

  case "$key" in
    -f) 
    shift; 
    FORCEMODE=1;
    ;;

    -v)
    shift;
    VERBOSE=1;   
    ;; 

    --dev)
    DEV=$2
    shift;
    shift;
    ;;

    *)
    shift;
    ;;
  esac
done

function draw(){
  if [[ $VERBOSE -eq 1 ]];
  then 
    echo ${1}
  fi
}

if [[ -z $DEV ]];
then
  echo "echo \"----------------------------------------\""
  echo "echo \"No drive passed, use --dev /dev/<device>\""
  echo "echo \"----------------------------------------\""
  exit
fi

if [[ `echo $DEV | grep -Eo "/dev/sd[a-z][a-z]?" -c` -eq 0 ]];
then
  echo "echo \"----------------------------------\""
  echo "echo \"Argument malformed, check spelling\""
  echo "echo \"----------------------------------\""
  exit
fi

echo $INITSTATE | grep -q "HEALTH_OK"
if [[ $? -eq 1 ]]; 
then
  if [[ $FORCEMODE -eq 0 ]];
  then
    echo "echo \"Ceph is $INITSTATE, aborting\""
    echo "echo \"Please retry in a while\""
    exit
  else
    draw "Ceph is $INITSTATE"
  fi
fi

OSD=`ceph device ls | grep $HOSTNAME | grep $DEVID | awk '{ print $3 }' | sed -e 's/osd.//'`

if [[ -z $OSD ]];
then
  # try automatically resolve OSD with ceph osd tree down
fi

if [[ -z $DBD ]];
then
  # identify if there are db devices on this cluster. 
  if [[ `ceph device ls | grep $HOSTNAME | grep -E "osd.[0-9]+ osd.[0-9]+"` ]];
  then
    DBD="/dev/`ceph device ls | grep $HOSTNAME | grep -E "osd.[0-9]+ osd.[0-9]+" | grep osd.$OSD | awk '{ print $2 }' | sed -e 's/.*://'`"
  fi
fi



# cat beesly.inventory | jq '. | map(select(.available))'

# how many drives per osd : ceph device ls | grep $HOSTNAME | grep -Eo "osd.[0-9]+" | sort  | uniq -c | sed -e 's/osd.*$//' | uniq | tr -d " " 
# erin: 2

# testing osd id from ceph inventory: 
# ceph-volume inventory --format=json | jq '. | map(select(.lvs | contains([{}]))) | map(select(.path | contains("/dev/sdg")))'

# ceph-volume inventory --format=json | jq '. | map(select(.lvs | contains([{}]))) | map(select(.path | contains("/dev/sdg"))) | .[].lvs | .[].osd_id' | tr -d "\""

# get an osd's drives
# cat erin.inventory |  jq '. | map(select(.lvs | contains([{}]))) |  map(select(.lvs | .[0].osd_id | contains("362")) | .path)'

# getting available drives
# cat ~/beesly.inventory |  jq '. | map(select(.available==true) | .path)'


