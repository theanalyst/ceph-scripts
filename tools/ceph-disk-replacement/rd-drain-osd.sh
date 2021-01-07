#!/bin/bash

## Ceph Version check
ret=`ceph -v | awk '{ print $3 }' | awk -F . '{ if( $1 >= 14) { print $0 } }'`

if [[ -z $ret ]];
then
  echo "Requires at least ceph nautilus"
  echo "please use './drain-osd.sh --dev <device>' instead"
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


if [[ `cat /etc/motd | grep hostgroup | grep -Eo "ceph/[a-Z0-9/]+" | grep -c nethub` -eq 1 ]];
then
  echo "cephnethub intervention ongoing. please retry in a couple of days."
  exit -1
fi



INITSTATE=`ceph health`
FORCEMODE=0;
VERBOSE=0
BLUESTORE=0;

cluster=`/opt/puppetlabs/bin/facter hostgroup_1`

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

DEVID=`echo $DEV | grep -Eo "sd[a-z]+"`

if [[ `cat /sys/block/${DEVID}/queue/rotational` -eq 0 ]];
then
    echo "echo \"SSD detected, contact ceph-admins\"";
    exit -1
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
    draw "# Ceph is $INITSTATE"
  fi
fi

OSD=`ceph-volume inventory --format=json | jq --arg DEV "$DEV" '. | map(select(.lvs | contains([{}]))) | map(select(.path==$DEV)) | .[].lvs | .[].osd_id' | tr -d "\""`

if [[ -z $OSD ]];
then
  OSD=`ceph device ls | grep $HOSTNAME | grep "$DEVID " | awk '{ print $3 }' | sed -e 's/osd.//'`
  if [[ -z $OSD ]];
  then
    echo "echo \" No OSD mapped to drive $DEV. \""
    exit
  fi
fi

if [[ `ceph osd ok-to-stop osd.$OSD &> /dev/null` -eq 0 ]];
then
  echo "ceph osd out osd.$OSD;"
  echo "ceph osd primary-affinity osd.$OSD 0;"
  echo "touch /root/log.${cluster}.drain.${HOSTNAME}.${OSD}"
  echo "while [ \`ceph osd df tree --filter_by=name --filter=osd.$OSD --format=json | jq '.nodes[].pgs'\` --ne 0 ]; do"
  echo "sleep 600; echo \"Draining in progress... (\`ceph osd df tree --filter_by=name --filter=osd.$OSD --format=json | jq '.nodes[].pgs'\`)\";"
  echo "done;"
  echo "systemctl stop ceph-osd@$OSD"
  echo "if ! \`ceph osd safe-to-destroy osd.$OSD &> /dev/null\`"
  echo "then echo \"OSD unsafe to destroy, please contact ceph-admins\";"
  echo "else"
  echo "umount /var/lib/ceph/osd/ceph-$OSD"
  echo "ceph-volume lvm zap --destroy --osd-id $OSD"
  echo "touch /root/log.${cluster}.prepare.${HOSTNAME}.${OSD}"
  echo "rm -f /root/log.${cluster}.drain.${HOSTNAME}.${OSD}"
  echo "ceph osd destroy $OSD --yes-i-really-mean-it"
  echo "fi"
fi


