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


DEVID=`echo $DEV | grep -Eo "sd[a-z]+"`
OSD=`ceph device ls | grep $HOSTNAME | grep $DEVID | awk '{ print $3 }' | sed -e 's/osd.//'`

if [[ -z $OSD ]];
then
  echo "echo \" No OSD mapped to drive $DEV. \""
  exit
fi

if [[ `systemctl is-active ceph-osd@$OSD --quiet;` -eq 0 ]];
then
  draw "osd.$OSD is active"
  if [[ `ceph osd ok-to-stop osd.$OSD &> /dev/null` -eq 0 ]];
  then
    echo "ceph osd out osd.$OSD;"
    echo "ceph osd primary-affinity osd.$OSD 0;"
  fi
else
  echo "echo \"osd.$OSD is already out, draining.\""
fi



