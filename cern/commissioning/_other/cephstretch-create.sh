##
# This is to create a Ceph stretch cluster for testing
##

#!/bin/bash -x


create_vm () {
  local VM_NAME=$1
  local AZ=$2

  ai-bs     --landb-mainuser ceph-admins \
            --landb-responsible ceph-admins \
            --nova-flavor $FLAVOR \
            --cs8 \
            --foreman-environment 'production' \
            --foreman-hostgroup 'ceph/spare' \
	    --nova-availabilityzone $AZ \
	    $VM_NAME
}

create_volume () {
  local VOLUME_NAME=$1
  local AZ=$2

  openstack volume create \
	  --size 100 \
	  --type standard \
	  --availability-zone $AZ \
	  $VOLUME_NAME
}

unset OS_PROJECT_ID;
unset OS_TENANT_ID;
unset OS_TENANT_NAME;
export OS_PROJECT_NAME="Ceph Development";

openstack server list  > /dev/null 2>&1
if [ $? != "0" ] ; then
  echo "openstack server list not working"
  exit
fi

NAME_PREFIX='cephstretch'
FLAVOR='m2.large'

create_vm $NAME_PREFIX-a-1 cern-geneva-a
create_vm $NAME_PREFIX-a-2 cern-geneva-a
create_vm $NAME_PREFIX-a-3 cern-geneva-a
create_vm $NAME_PREFIX-b-1 cern-geneva-b
create_vm $NAME_PREFIX-b-2 cern-geneva-b
create_vm $NAME_PREFIX-c-1 cern-geneva-c

create_volume $NAME_PREFIX-a-1 ceph-geneva-1
create_volume $NAME_PREFIX-a-2 ceph-geneva-1
create_volume $NAME_PREFIX-a-3 ceph-geneva-1
create_volume $NAME_PREFIX-b-1 ceph-geneva-2
create_volume $NAME_PREFIX-b-2 ceph-geneva-2
