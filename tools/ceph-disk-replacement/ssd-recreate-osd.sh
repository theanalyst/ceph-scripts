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

        --db)
        DBD=$2  
        shift;
        shift;
        ;;

        --osd)
        OSD=$2
        shift;
        shift;
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
    draw "# Ceph is $INITSTATE"
  fi
fi



OSDS=`lvs -odevices,tags | grep $DEV | grep type=db | grep -Eo "osd_id=[0-9]+" | grep -Eo [=0-9]+ | tr -d "\n" | sed -e 's/=/ /g' `

for i in `echo $OSDS`;
do
  DEVS=` echo -n "$DEVS "; lvs -odevices,tags | grep osd_id=$i | grep -v type=db | grep -Eo /dev/sd[a-z]+`; 
done



for i in `echo $OSDS`; 
do
  ceph osd safe-to-destroy osd.$i &> /dev/null
  retval=`echo $?`
  if [[ $retval -ne 0 ]];
  then
    echo $INITSTATE | grep -q "HEALTH_OK"
    if [[ $? -eq 1 ]];
    then
      echo "echo \"osd.$i is unsafe to destroy\"" 
      echo "echo \"Please wait and try again later\""
      echo "echo \"Aborting\"" 
      exit
    fi  
  fi
done

for i in `echo $OSDS`;
do
  echo "ceph osd destroy $i --yes-i-really-mean-it"
done

for i in `echo $DEVS`;
do
    echo "ceph-volume lvm zap $i --destroy"
done


echo "ceph-volume lvm zap $DEV"
echo "ceph-volume lvm batch $DEV $DEVS --osd-ids $OSDS"

for i in `echo $OSDS`;
do
  echo "ceph osd primary-affinity $i 1"
done

# ceph-volume lvm batch /dev/sdp /dev/sdae /dev/sdd /dev/sdh /dev/sdl /dev/sdt /dev/sdx --osd-ids 220 338 447 1406 1430 1459

## TODO
#
# Auto discover osd to be replaced (grep on ceph osd tree down to find down osd on the host)
# Auto find if 2-disk OSDs are used

 
#  awk 'BEGIN { out=0 } { if($0 ~ /rack/) {out=0} if(out) {print $0} if($0 ~ /RJ55/) {out=1}; } '
