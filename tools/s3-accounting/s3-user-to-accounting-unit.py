#! /usr/bin/python -u

import os
from os_client_config import config as cloud_config
from keystoneauth1 import session as keystone_session

from keystoneclient.v3 import client as keystone_client
from cinderclient.v3 import client as cinder_client
from manilaclient.v2 import client as manila_client
from manilaclient import api_versions as manila_api_versions


cc = cloud_config.OpenStackConfig()
cloud = cc.get_one_cloud(cloud=os.environ.get('OS_CLOUD'))
session = keystone_session.Session(auth=cloud.get_auth())

keystoneclient = keystone_client.Client(session=session)
cinderclient = cinder_client.Client(session=session)
manilaclient = manila_client.Client(
                api_version=manila_api_versions.APIVersion('2.39'),
                            session=session)

# openstack volume show
volume = cinderclient.volumes.get('7ca9919b-f270-4fdf-ad7b-5a45ad4a9036')
project_id = getattr(volume, 'os-vol-tenant-attr:tenant_id')

# openstack project show
project = keystoneclient.projects.get(project_id)


accounting_group = getattr(project,'accounting-group')

role = keystoneclient.roles.find(name='owner') 
role_id = getattr(role,'id')

role_assig = keystoneclient.role_assignments.list(project=project_id,role=role_id)
user_id = role_assig[0].user['id']

user = keystoneclient.users.get(user_id)
accounting = getattr(user,'department')

print accounting

