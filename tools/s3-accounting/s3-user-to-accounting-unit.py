#! /usr/bin/python2 -u

import os
from os_client_config import config as cloud_config
from keystoneauth1 import session as keystone_session

from keystoneclient.v3 import client as keystone_client
from cinderclient.v3 import client as cinder_client
from manilaclient.v2 import client as manila_client
from manilaclient import api_versions as manila_api_versions

import sys

if len (sys.argv) != 2:
  print "No project_id given"
  exit(-1)

cc = cloud_config.OpenStackConfig()
cloud = cc.get_one_cloud(cloud='cern') # try with 'cern'
session = keystone_session.Session(auth=cloud.get_auth())

keystoneclient = keystone_client.Client(session=session)
cinderclient = cinder_client.Client(session=session)
manilaclient = manila_client.Client(
                api_version=manila_api_versions.APIVersion('2.39'),
                            session=session)

outstr=""

# openstack volume show
#volume = cinderclient.volumes.get(sys.argv[1])
project_id = sys.argv[1];# getattr(volume, 'os-vol-tenant-attr:tenant_id')
try: 
#try: 
  # openstack project show
  project = keystoneclient.projects.get(project_id)
  accounting_group = getattr(project,'accounting-group')

  if hasattr(project, 'chargegroup'):
    outstr="chargegroup: "+project.chargegroup+", chargerole: "+project.chargerole

  role = keystoneclient.roles.find(name='owner') 
  role_id = getattr(role,'id')

  role_assig = keystoneclient.role_assignments.list(project=project_id,role=role_id)
  user_id = role_assig[0].user['id']

  user = keystoneclient.users.get(user_id)

except:
  try:
    user = keystoneclient.users.get(project_id)
  except:
    user = "Unknown"

try:
  username = getattr(user,'id')
except:
  username = "Unknown"

print username+" "+outstr 
