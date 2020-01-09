#! /bin/bash

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

# How many drives per OSD?
NUM=`lvs -o +devices,tags | grep type=block | grep osd_id=$OSD | grep -oE "/dev/.* " | grep  "dev/sd[a-z]*" -o | wc -l`
if [[ $NUM -gt 1 ]];
then
  draw "osd.$OSD has $NUM drives"
  echo "echo \"Please note that the OSD was using the following drives: `lvs -o +devices,tags | grep type=block | grep osd_id=$OSD | grep -oE "/dev/.* " | sed 's/([0-9])//g'`\""
fi


draw "$DEV is osd.$OSD"
ceph osd safe-to-destroy osd.$OSD &> /dev/null
retval=`echo $?`

if [[ $retval -eq 0 ]];
then
  echo "systemctl stop ceph-osd@$OSD"
  echo "umount /var/lib/ceph/osd/ceph-$OSD"
  if [[ $CASTOR -eq 1 ]]; then
    echo "ceph-volume lvm zap --destroy --osd-id $OSD"
  else
    echo "ceph-volume lvm zap $DEV --destroy"
  fi
else
  echo "echo \"osd.$OSD still unsafe to destroy\"" 
  echo "echo \"Please wait and retry later\""
fi


 
