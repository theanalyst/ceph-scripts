#!/bin/bash

while [[ $# -gt 0 ]]
do
  key="$1"

  case "$key" in
    -f) 
    shift; 
    ERASE=1;
    ;;

    -b)
    bucket=$2
    shift;
    shift;
    ;;

    *)
    shift;
    ;;
  esac
done

if [[ -z $bucket ]];
then 
  echo "no bucket provided, use -b <bucket name>"
  exit
fi 

if [[ -z $ERASE ]];
then
  echo "Dry-run mode. run with -f to actually remove objects"
fi

set -e

echo "Removing all versions from $bucket"

versions=`aws --endpoint-url=http://s3.cern.ch s3api list-object-versions --bucket $bucket |jq '.Versions'`
markers=`aws --endpoint-url=http://s3.cern.ch s3api list-object-versions --bucket $bucket |jq '.DeleteMarkers'`

echo "removing files"
for version in $(echo "${versions}" | jq -r '.[] | @base64'); do
    version=$(echo ${version} | base64 --decode)

    key=`echo $version | jq -r .Key`
    versionId=`echo $version | jq -r .VersionId `
    cmd="aws --endpoint-url=http://s3.cern.ch s3api delete-object --bucket $bucket --key '$key' --version-id='$versionId'"
    echo $cmd
    if [[ ! -z $ERASE ]];
    then
      eval $cmd
    fi
done

echo "removing delete markers"
for marker in $(echo "${markers}" | jq -r '.[] | @base64'); do
    marker=$(echo ${marker} | base64 --decode)

    key=`echo $marker | jq -r .Key`
    versionId=`echo $marker | jq -r .VersionId `
    cmd="aws --endpoint-url=http://s3.cern.ch s3api delete-object --bucket $bucket --key '$key' --version-id='$versionId'"
    echo $cmd
    if [[ ! -z $ERASE ]];
    then
      eval $cmd
    fi
done
