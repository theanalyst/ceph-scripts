#! /bin/bash

## Ceph Version check
ret=`ceph -v | awk '{ print $3 }' | awk -F . '{ if( $1 < 14) { print $0 } }'`

if [[ -z $ret ]];
then
  echo "ceph nautilus detected."
  echo "please use './naut-drain-osd.sh --dev <device>' instead"
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


pvscan --cache

echo $INITSTATE | grep -q "HEALTH_OK"
if [[ $? -eq 1 ]]; 
then
  if [[ $FORCEMODE -eq 0 ]];
  then
    echo "echo \"Ceph is $INITSTATE, aborting\""
    echo "echo \"Please retry in a while\""
    exit
  else
    draw "# Ceph is $INITSTATE"
  fi
fi

OSD=`lvs -o +devices,tags | grep "$DEV" | grep -E "type=block" | grep -Eo "osd_id=[0-9]+" | tr -d "[a-z=_]"`

if [[ -z $OSD ]];
then
  draw "# No bluestore osd found, going through ceph-disk for filestore osds."
  OSD=`ceph-disk list 2>/dev/null | grep "^ $DEV" | grep -oE "osd\.[0-9]+" | tr -d "[osd\.]"`
fi

if [[ -z $OSD ]];
then
  echo "echo \"$DEV has no OSD mapped to it.\""
  exit;
fi 

draw "$DEV is osd.$OSD"

if [[ `systemctl is-active ceph-osd@$OSD --quiet;` -eq 0 ]];
then
  draw "osd.$OSD is active"
  if [[ `ceph osd ok-to-stop osd.$OSD &> /dev/null` -eq 0 ]];
  then
    echo "ceph osd out osd.$OSD;"
    echo "ceph osd primary-affinity osd.$OSD 0;"
    echo "touch /tmp/log.drain.${HOSTNAME}.${OSD}"
  fi
else
  echo "echo \"osd.$OSD is already out draining.\""
fi


 
