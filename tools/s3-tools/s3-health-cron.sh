#! /bin/bash


HOSTNAME='s3.cern.ch'
TIMEOUT=3
TELEGRAM_SEND='/afs/cern.ch/user/e/ebocchi/.local/bin/telegram-send'


timeout $TIMEOUT fping $HOSTNAME > /dev/null 2>&1
RETVAL=$?

if [ $RETVAL -ne 0 ]; then
  $TELEGRAM_SEND "Unable to ping $HOSTNAME. Please check!"
else
  timeout $TIMEOUT s3cmd ls > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    $TELEGRAM_SEND "Unable to \`s3cmd ls\`. S3 service seems down. Please check!"
  fi
fi 


