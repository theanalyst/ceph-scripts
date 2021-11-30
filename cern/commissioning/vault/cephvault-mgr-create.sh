## 
# This is to run Ceph Octopus MGR on C8 (leaving the rest on CC7)
##

#!/bin/bash -x

unset OS_PROJECT_ID;
unset OS_TENANT_ID;
unset OS_TENANT_NAME;
export OS_PROJECT_NAME="IT Ceph Storage Service";

openstack server list  > /dev/null 2>&1
if [ $? != "0" ] ; then
  echo "openstack server list not working"
  exit
fi

PREFIX='cephvault-mgr-'
FLAVOR='m2.large'
VM_ZONE="cern-geneva-a"
#VM_ZONE="cern-geneva-b"
#VM_ZONE="cern-geneva-c"


ai-bs     --landb-mainuser ceph-admins \
          --landb-responsible ceph-admins \
	  --c8 \
          --nova-sshkey ebocchi \
          --nova-flavor $FLAVOR \
          --nova-parameter 'cern-datacentre=meyrin' \
          --nova-availabilityzone $VM_ZONE \
          --foreman-hostgroup 'ceph/spare' \
          --foreman-environment 'production' \
          --roger-appstate 'build' \
          --prefix $PREFIX
