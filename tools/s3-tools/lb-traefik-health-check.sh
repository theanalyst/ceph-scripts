#! /bin/bash

num_backends=`curl -s -u $1:$2 http://localhost/traefik/api/providers/consul_catalog/backends | jq '.' | grep backend | wc -l`

if [[ $num_backends > 0 ]];
then
    exit 0
else
    exit -1
fi

