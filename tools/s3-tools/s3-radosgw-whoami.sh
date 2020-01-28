#!/bin/bash

PIDRGW=$(pidof radosgw)

if [[ $PIDRGW ]];
then
    OUTPUT=$(xargs --null --max-args=1 echo < /proc/$PIDRGW/environ | grep NOMAD_JOB_NAME | cut -d'=' -f2)
    if [[ $OUTPUT ]]; 
    then
        echo -n "$OUTPUT"
    fi
fi
 
