#!/bin/bash -x

#
# Use as:
# ./create-ceph-consul-testing.sh
#

unset OS_PROJECT_ID;
unset OS_TENANT_ID;
unset OS_TENANT_NAME;
export OS_PROJECT_NAME="IT Ceph Storage Service";


# Basic functional test for OpenStack
openstack server list  > /dev/null 2>&1
if [ $? != "0" ] ; then
  echo "openstack server list not working"
  exit
fi


# Define VM name prefix
VM_NAME_PREFIX="cephgabe-rgwxl-"

# Environment and hostgroup for testing
VM_ENVIRONMENT="production"
VM_HOSTGROUP="ceph/gabe/radosgw/hashi"

# VM flavor
VM_FLAVOR="m2.xlarge"


# Create the VM
ai-bs     --landb-mainuser CEPH-ADMINS \
          --landb-responsible CEPH-ADMINS \
          --landb-ipv6ready \
          --cc7 \
          --nova-flavor $VM_FLAVOR \
          --nova-parameter 'cern-datacentre=meyrin' \
          --foreman-environment $VM_ENVIRONMENT \
          --foreman-hostgroup $VM_HOSTGROUP \
  	  --roger-appstate 'build' \
          --prefix $VM_NAME_PREFIX

