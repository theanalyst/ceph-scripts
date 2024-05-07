## 
# This is to create a tiebreaker mon in the Barn for the Toby cluster
#
#  Critical power is not a hardly needed, but the Barn is the only place
#  where there is equal network connectivity against Main Room, Vault, and 773
##

#!/bin/bash -x

unset OS_PROJECT_ID;
unset OS_TENANT_ID;
unset OS_TENANT_NAME;
export OS_PROJECT_NAME="IT Ceph Storage Service";
export OS_REGION_NAME="cern";

openstack server list  > /dev/null 2>&1
if [ $? != "0" ] ; then
  echo "openstack server list not working"
  exit
fi

PREFIX='cephtoby-mon-513-'
FLAVOR='m2.large'

# Define VM availability zone
VM_ZONE="cern-geneva-a"
#VM_ZONE="cern-geneva-b"
#VM_ZONE="cern-geneva-c"


ai-bs     --landb-mainuser ceph-admins \
          --landb-responsible ceph-admins \
          --nova-flavor $FLAVOR \
          --rhel9 \
	  --nova-availabilityzone $VM_ZONE \
          --foreman-environment 'production' \
          --foreman-hostgroup 'ceph/toby/mon' \
          --prefix $PREFIX
