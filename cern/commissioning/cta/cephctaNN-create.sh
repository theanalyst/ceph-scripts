##
# This is for new nodes to be added to the CTA cluster
#   See RQF2503811 (https://cern.service-now.com/service-portal?id=ticket&table=u_request_fulfillment&n=RQF2503811)
#
# 1. Instantiate a first time with this script. Only one device will be used as system disk, no mdraid.
# 2. If the node has two devices that can be used as system disks, reinstall with the following commands to configure mdraid"
#     eval $(ai-rc "IT Ceph Ironic")
#     ai-foreman updatehost -p 'Ceph (XFS)' --operatingsystem "RHEL 8.9" -m RedHatCERN $HOST
#     ai-installhost --mode=bios $HOST
#     openstack server reboot --hard $HOST
##

#!/bin/bash -x

unset OS_PROJECT_ID;
unset OS_TENANT_ID;
unset OS_TENANT_NAME;
export OS_PROJECT_NAME="IT Ceph Ironic";

openstack server list  > /dev/null 2>&1
if [ $? != "0" ] ; then
  echo "openstack server list not working"
  exit
fi

HOSTNAME='cephcta07'
#HOSTNAME='cephcta08'
FLAVOR='p1.ca6394397.S513-V-IP825'
#FLAVOR='p1.dl8643778.S513-V-IP85'

ai-bs     --landb-mainuser ceph-admins \
          --landb-responsible ceph-admins \
          --nova-flavor $FLAVOR \
          --rhel8 \
          --foreman-environment 'production' \
          --foreman-hostgroup 'ceph/spare' \
          $HOSTNAME
