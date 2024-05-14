#!/bin/bash -x

#
# Use as:
# ./cephstanpre-rgw-create.sh
#

unset OS_PROJECT_ID;
unset OS_TENANT_ID;
unset OS_TENANT_NAME;
export OS_PROJECT_NAME="IT Ceph Storage Service";
export OS_REGION_NAME="pdc";


# Basic functional test for OpenStack
openstack server list  > /dev/null 2>&1
if [ $? != "0" ] ; then
  echo "openstack server list not working"
  exit
fi


# Define VM name prefix
VM_NAME_PREFIX="cephstanpre-rgw-"

# Environment and hostgroup for testing
VM_ENVIRONMENT="production"
VM_HOSTGROUP="ceph/spare"

# VM flavor
VM_FLAVOR="m4.xlarge"    # 8 CPUs, 32GB, 80GB
#VM_FLAVOR="m4.2xlarge"  # 16 CPUs, 64GB, 160GB

# OS
OS="rhel9"  # RHEL 9

# Availability zones are not available in PDC.
# Let's use soft-anti-affinity to make sure the VMs do not land on the same hypervisor
#
# Affinity and anti-affinity filters extended with zone (rack) and location (room)
#   – soft vs hard (cloud prefers soft as it gives them more leeway if they need to migrate VMs)
#   – scope: Host, Zone (rack), Location (room)
#   – max_server_per_scope
#
#   $ openstack server group create \
#       --policy soft-anti-affinity \
#       --rule scope=zone \
#       --rule max_server_per_scope=1 \
#       one_per_rack
#
#   +------------+----------------------------------------+
#   | Field      | Value                                  |
#   +------------+----------------------------------------+
#   | id         | 310ffccf-5e18-4374-b840-61ad38f29253   |
#   | members    |                                        |
#   | name       | one_per_rack                           |
#   | policy     | soft-anti-affinity                     |
#   | project_id | 5d8ea54e-697d-446f-98f3-da1ce8f8b833   |
#   | rules      | max_server_per_scope='1', scope='zone' |
#   | user_id    | ebocchi                                |
#   +------------+----------------------------------------+
#

# Create the VM
ai-bs     --landb-mainuser CEPH-ADMINS \
          --landb-responsible CEPH-ADMINS \
          --landb-ipv6ready \
          --$OS \
          --nova-flavor $VM_FLAVOR \
	  --nova-hint 'group=310ffccf-5e18-4374-b840-61ad38f29253' \
          --foreman-hostgroup $VM_HOSTGROUP \
	  --foreman-environment $VM_ENVIRONMENT \
  	  --roger-appstate 'build' \
          --prefix $VM_NAME_PREFIX
