#! /bin/bash
#
# usage: ./list-rgw-local-users.sh
#
# Returns csv list of users created on the radosgws which exist only locally,
#   i.e., Openstack has no knowledge of these accounts.
#
# The list reports:
#   1. user_id
#   2. display_name
#   3. email
#
# This is used for accounting purposes with a manual (human) mapping 
#   between the local user and the accountable experiment/group.
#
# This list is stored on S3 at s3://s3-accounting-files/local_rgw_users
#

all_users=$(radosgw-admin --cluster=gabe user list | jq '.[]' | tr -d "\"")
local_users=$(echo "$all_users" | grep -Ev "[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}" | sort)

echo "#user_id,display_name,email"
for user in $local_users;
do
  radosgw-admin --cluster=gabe user info --uid=$user | jq -r '[.user_id, .display_name, .email] | @csv'
  #radosgw-admin --cluster=gabe user info --uid=$user | jq '{(.user_id):{user_id:.user_id, display_name:.display_name, email:.email}}'
done

