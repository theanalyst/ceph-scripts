#!/bin/bash

HOSTNAME='s3.cern.ch'
HOSTCOUNT_THRESHOLD=6
TIMEOUT=10
TELEGRAM_SEND='/afs/cern.ch/user/e/ebocchi/.local/bin/telegram-send'
SLACKPOST='/afs/cern.ch/user/e/ebocchi/it-puppet-hostgroup-ceph/code/files/slackpost'

timeout $TIMEOUT ping -c 1 $HOSTNAME > /dev/null 2>&1
if [ $? -ne 0 ]; then
  $TELEGRAM_SEND "Unable to ping $HOSTNAME. Please check!"
else
  IPv4=$(timeout $TIMEOUT host $HOSTNAME | grep "has address" | wc -l)
  IPv6=$(timeout $TIMEOUT host $HOSTNAME | grep "has IPv6 address" | wc -l)

  if [ $IPv4 -le $HOSTCOUNT_THRESHOLD ]; then
    $TELEGRAM_SEND "$HOSTNAME has only $IPv4 IPv4 addresses in the alias!"
    $SLACKPOST 'ceph_hostcount' "$HOSTNAME has only $IPv4 IPv4 addresses in the alias!"
  fi
  if [ $IPv6 -le $HOSTCOUNT_THRESHOLD ]; then
    $TELEGRAM_SEND "$HOSTNAME has only $IPv6 IPv6 addresses in the alias!"
    $SLACKPOST 'ceph_hostcount' "$HOSTNAME has only $IPv4 IPv6 addresses in the alias!"
  fi
fi
