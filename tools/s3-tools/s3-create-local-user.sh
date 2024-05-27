#!/bin/bash

#
# Use to create local S3 user
#   Example: `./s3-create-local-user.sh cvmfs-atlas lxcvmfs-atlas@cern.ch cvmfs-atlas 5000G`
#   to create a new user on S3 with uid=cvmfs-atlas, email=lxcvmfs-atlas@cern.ch, display-name=cvmfs-atlas, and a quota of 5TB
#
# The script will output the commands to be executed.
# Once checked, the creation of the user can be automated by piping to shell.
#


if [ "$#" -ne 4 ]; then
  echo "Illegal number of parameters"
  echo "Usage: s3-create-local-user.sh <uid> <email> <display-name> <quota>"
  exit 1
fi

USERID=$1
EMAIL=$2
DISPLAY=$3
QUOTA=$4
echo "radosgw-admin user create --uid=${USERID} --email=\"${EMAIL}\" --display-name=\"${DISPLAY}\""
echo "radosgw-admin quota set --quota-scope=user --uid=${USERID} --max-size=${QUOTA}"
echo "radosgw-admin quota enable --quota-scope=user --uid=${USERID}"

