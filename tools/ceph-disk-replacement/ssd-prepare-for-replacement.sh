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

OSD=`lvs -o +devices,tags | grep "$DEV" | grep -E "type=db" | grep -Eo "osd_id=[0-9]+" | tr -d "[a-z=_]"`

if [[ -z $OSD ]];
then
  echo "echo \"$DEV has no OSD mapped to it.\""
  exit;
fi 

# How many drives per OSD?
for i in `echo $OSD`;
do
    NUM=`lvs -o +devices,tags | grep type=db | grep osd_id=$i | grep -oE "/dev/.* " | grep  "dev/sd[a-z]*" -o | wc -l`
    if [[ $NUM -gt 1 ]];
    then
      draw "osd.$i has $NUM drives"
      echo "echo \"Please note that the OSD was using the following drives: `lvs -o +devices,tags | grep type=block | grep osd_id=$i | grep -oE "/dev/.* " | sed 's/([0-9])//g'`\""
    fi
done

draw "$DEV is osd.$OSD"
ceph osd safe-to-destroy osd.$OSD &> /dev/null
retval=`echo $?`

for i in `echo $OSD`;
do
    if [[ $retval -ne 0 ]];
    then
      echo "systemctl stop ceph-osd@$i"
      echo "umount /var/lib/ceph/osd/ceph-$i"
    else
      echo "echo \"osd.$i still unsafe to destroy\"" 
      echo "echo \"Please wait and retry later\""
    fi
done

 
