##
# This is to create a mini-gabe cluster for testing
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

PREFIX='ceph-proxy-'
FLAVOR='m2.small'
#VM_ZONE="cern-geneva-a"
#VM_ZONE="cern-geneva-b"
#VM_ZONE="cern-geneva-c"

ai-bs     --landb-mainuser ceph-admins \
          --landb-responsible ceph-admins \
	  --nova-sshkey ebocchi \
          --nova-flavor $FLAVOR \
          --cs8 \
          --foreman-environment 'production' \
          --foreman-hostgroup 'ceph/proxy' \
          --prefix $PREFIX
