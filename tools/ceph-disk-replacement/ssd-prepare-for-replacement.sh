#! /bin/bash

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

    --bad)
    BADOSD=$2
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

DEV=`echo $DEV | sed -e 's/\/dev\///'`
 
OSD=`lvs -o +devices,tags | grep "/dev/$DEV" | grep -E "type=db" | grep -Eo "osd_id=[0-9]+" | tr -d "[a-z=_]"`

if [[ -z $OSD ]];
then
    OSD=`ceph device ls | grep $HOSTNAME | grep $DEV | awk 'BEGIN{FS=":"} {print $2}' | tr -d "[a-z.]"`
fi 
  
echo "mkdir -p /etc/ceph/osd-bak/"
echo "cp -a /etc/ceph/osd/* /etc/ceph/osd-bak/"

# How many drives per OSD?
for i in `echo $OSD`;
do
    echo "rm -f /etc/ceph/osd/$i-*"
    NUM=`lvs -o +devices,tags | grep type=db | grep osd_id=$i | grep -oE "/dev/.* " | grep  "dev/sd[a-z]*" -o | wc -l`
    if [[ $NUM -gt 1 ]];
    then
      draw "osd.$i has $NUM drives"
      echo "echo \"Please note that the OSD was using the following drives: `lvs -o +devices,tags | grep type=block | grep osd_id=$i | grep -oE "/dev/.* " | sed 's/([0-9])//g'`\""
    fi
done

if [[ $BADOSD ]];
then
  echo "rm -f /etc/ceph/osd/$BADOSD-*"
fi

draw "$DEV is osd.$OSD"
ceph osd ok-to-stop $OSD &> /dev/null
retval=`echo $?`


if [[ $retval -ne 0 ]];
then
  echo "not okay to stop"
  exit -1;
fi

echo "ceph osd set noout"
for i in `echo $OSD`;
do
  echo "systemctl stop ceph-osd@$i"
done

if [[ $BADOSD ]];
then
  echo "systemctl stop ceph-osd@$BADOSD"
fi

echo "sleep 5"
for i in `echo $OSD`;
do
  echo "umount /var/lib/ceph/osd/ceph-$i"
done

if [[ $BADOSD ]];
then
  echo "umount /var/lib/ceph/osd/ceph-$BADOSD"
  echo "ceph osd destroy $BADOSD --yes-i-really-mean-it"
  BADDEV=`ceph device ls | grep $HOSTNAME | grep -vE "osd.[0-9]+ osd.[0-9]+" | grep osd.$BADOSD | sed -e 's/.*://' | awk '{print $1}'`
  echo "ceph-volume lvm zap --destroy /dev/$BADDEV"
fi

