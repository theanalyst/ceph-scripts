## 
# This is for the HW delivery in January 2021
#
# Levinson cluster was moved to the Barn in November 2022
# See https://its.cern.ch/jira/browse/CEPH-1400
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

PREFIX='cephflash20-'
FLAVOR='p1.dl8180369.S513-A-IP120' # BA03
FLAVOR='p1.dl8180369.S513-A-IP121' # BA05
FLAVOR='p1.dl8180369.S513-A-IP122' # BA07

# RHEL_ID='68b56d3a-2910-4cdb-8bf5-28b358f9b865' #8.6
RHEL_ID='782183d5-4c0c-4a66-83a8-139846cf82ce' #8.7

ai-bs     --landb-mainuser ceph-admins \
          --landb-responsible ceph-admins \
          --nova-flavor $FLAVOR \
          -i $RHEL_ID \
          --foreman-environment 'production' \
          --foreman-hostgroup 'ceph/spare' \
          --prefix $PREFIX

