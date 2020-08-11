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


OSD=`lvs -o +devices,tags | grep "$DEV" | grep -E "type=db" | grep -Eo "osd_id=[0-9]+," | tr -d "[a-z=_\n]" | sed -e 's/,/ /g'`

if [[ -z $OSD ]];
then
    DEV=`echo $DEV | sed -e 's/\/dev\///'`
    OSD=`ceph device ls | grep $HOSTNAME | grep $DEV | awk 'BEGIN{FS=":"} {print $2}' | tr -d "[a-z.]"`
fi


for i in `echo $OSD`;
do
    if [[ `systemctl is-active ceph-osd@$i --quiet;` -eq 0 ]];
    then
        if [[ `ceph osd ok-to-stop osd.$i &> /dev/null` -eq 0 ]];
        then
            echo "ceph osd out osd.$i;"
            echo "ceph osd primary-affinity osd.$i 0;"
        fi
    else
        echo "echo \"osd.$i is already out draining.\""
    fi
done

