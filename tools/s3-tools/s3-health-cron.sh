#! /bin/bash


HOSTNAME='s3.cern.ch'
TIMEOUT=10
S3CMD_LS_RETRIES=3
TELEGRAM_SEND='/afs/cern.ch/user/e/ebocchi/.local/bin/telegram-send'
SLACKPOST='/afs/cern.ch/user/e/ebocchi/it-puppet-hostgroup-ceph/code/files/slackpost'


# Make sure you have the tooling to send alert messages
if [ ! -f $TELEGRAM_SEND ]; then
  echo "ERROR: TelegramSend script not found! ($TELEGRAM_SEND)"
  exit 1
fi
if [ ! -f $SLACKPOST ]; then
  echo "ERROR: Slackpost script not found! ($SLACKPOST)"
  exit 1
fi


# Checks with `s3cmd ls`
failure=0
for r in $(seq 0 $S3CMD_LS_RETRIES)
do
  sleep $((2 ** $r))
  timeout $TIMEOUT s3cmd ls > /dev/null 2>&1
  rc=$?
  # If successful at the first attemp, assume service is good
  if [ $rc -eq 0 ] && [ $r -eq 0 ]; then
    break
  fi
  if [ $rc -ne 0 ]; then
    failure=$((failure+1))
  fi
done

total_retries=$((S3CMD_LS_RETRIES+1))
if [ $failure -gt 0 ];
then
  if [ $failure -eq $total_retries ]; then
    $TELEGRAM_SEND "\`s3cmd ls\` failed. S3 service seems down. Please check!"
    $SLACKPOST 's3cmd_ls' "\`s3cmd ls\` failed. S3 service seems down. Please check!"
  else
    $TELEGRAM_SEND "\`s3cmd ls\` failed $failure times out of $total_retries tested. Please check!"
    $SLACKPOST 's3cmd_ls' "\`s3cmd ls\` failed $failure times out of $total_retries tested. Please check!"
  fi
fi


# Checks with `curl`
s3_hosts_v4=$(timeout $TIMEOUT host $HOSTNAME | grep "has address" | rev | cut -d ' ' -f 1 | rev )
for ip in $s3_hosts_v4
do
  timeout $TIMEOUT curl -s -X GET http://$ip >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    $TELEGRAM_SEND "Unable to \`curl\` S3 via $ip. Please check!"
    $SLACKPOST 's3_curl' "Unable to \`curl\` S3 via $ip. Please check!"
  fi
done
s3_hosts_v6=$(timeout $TIMEOUT host $HOSTNAME | grep "has IPv6 address" | rev | cut -d ' ' -f 1 | rev )
for ip in $s3_hosts_v6
do
  timeout $TIMEOUT curl -g -6 -X GET http://[$ip] >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    $TELEGRAM_SEND "Unable to \`curl\` S3 via $ip. Please check!"
    $SLACKPOST 's3_curl' "Unable to \`curl\` S3 via $ip. Please check!"
  fi
done

