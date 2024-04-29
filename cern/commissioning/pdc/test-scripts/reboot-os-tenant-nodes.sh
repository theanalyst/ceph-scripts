#!/bin/bash 
unset OS_PROJECT_ID;
unset OS_TENANT_ID;
unset OS_TENANT_NAME;
export OS_PROJECT_NAME="IT Ceph Ironic";
export OS_REGION_NAME="pdc";

openstack server list  > /dev/null 2>&1
if [ $? != "0" ] ; then
  echo "openstack server list not working"
  exit
fi


HOSTS=$(openstack server list | awk '{print $4}' | grep 'ceph' | xargs)
TOTAL=0

for host in $HOSTS; do
	TOTAL=$(($TOTAL+1))
	 echo "REBOOTING $host"
	 roger update --appstate production --all_alarms=false --duration 1h --message "reboot test of ceph pdc nodes" $host
	 ssh root@"$host" "reboot"
	 sleep 15
done
echo "$TOTAL hosts"~                                                                                                                                                                                                                                             
