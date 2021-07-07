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
VM_HOSTGROUP="ceph/gabe/radosgw/traefik"

# VM flavor
VM_FLAVOR="m2.xlarge"    # 8 CPUs, 16GB, 80GB
#VM_FLAVOR="m2.2xlarge"  # 16 CPUs, 32GB, 160GB
#VM_FLAVOR="r4.2xlarge"  # 20 CPUs, 64GB, 320GB

# OS
OS="c8"   # CentOS 8
#OS="cs8"  # CentOS Stream 8

# Define VM availability zone
VM_ZONE="cern-geneva-a"
#VM_ZONE="cern-geneva-b"
#VM_ZONE="cern-geneva-c"

# Create the VM
ai-bs     --landb-mainuser CEPH-ADMINS \
          --landb-responsible CEPH-ADMINS \
          --landb-ipv6ready \
          --$OS \
          --nova-flavor $VM_FLAVOR \
          --nova-parameter 'cern-datacentre=meyrin' \
          --nova-availabilityzone $VM_ZONE \
          --foreman-hostgroup $VM_HOSTGROUP \
	  --foreman-environment $VM_ENVIRONMENT \
  	  --roger-appstate 'build' \
          --prefix $VM_NAME_PREFIX

