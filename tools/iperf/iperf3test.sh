#!/bin/bash

SERVER=$1
iperf3 -c ${SERVER} -p 8000 --json > /tmp/iperf3.json

BPS=`jq .end.sum_sent.bits_per_second < /tmp/iperf3.json`

echo $BPS
