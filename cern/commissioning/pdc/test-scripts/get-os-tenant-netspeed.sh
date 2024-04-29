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
	echo "$host"
	ssh root@"$host" "ethtool eth2 | grep Speed"
	ssh root@"$host" "iperf3 -c cephmds24-a14f85fbf9 -p 80"
	echo ""
	echo ""
done

echo "$TOTAL hosts"~                                                                                                                                                                                                                                             
~                                                                                                                                                                                                                                             
~                                                                                                                                                                                                                                             
~                                                                                                                                                                                                                                             
~                           
