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

echo "YOU ARE IN TENANT:$OS_PROJECT_NAME REGION:$OS_REGION_NAME WAITING 30S before begining"
sleep 30 

HOSTS=$(openstack server list | awk '{print $4}' | grep 'ceph' | xargs)
TOTAL=0

for host in $HOSTS; do
	TOTAL=$(($TOTAL+1))
	echo "$host"
	ai-kill $host
	echo ""
	echo ""
done

echo "$TOTAL hosts"~                                                                                                                                                                                                                                             
~                                                                                                                                                                                                                                             
~                                                                                                                                                                                                                                             
~                                                                                                                                                                                                                                             
~                           
