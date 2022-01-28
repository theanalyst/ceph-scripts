##
# This is to create a mini-gabe cluster for testing
##

#!/bin/bash -x

unset OS_PROJECT_ID;
unset OS_TENANT_ID;
unset OS_TENANT_NAME;
export OS_PROJECT_NAME="Ceph Development";

openstack server list  > /dev/null 2>&1
if [ $? != "0" ] ; then
  echo "openstack server list not working"
  exit
fi

PREFIX='minigabe-'
FLAVOR='m2.large'
VM_ZONE="cern-geneva-a"
#VM_ZONE="cern-geneva-b"
#VM_ZONE="cern-geneva-c"

ai-bs     --landb-mainuser ceph-admins \
          --landb-responsible ceph-admins \
          --nova-flavor $FLAVOR \
          --cs8 \
          --foreman-environment 'production' \
          --foreman-hostgroup 'ceph/minigabe/mon' \
          --prefix $PREFIX
