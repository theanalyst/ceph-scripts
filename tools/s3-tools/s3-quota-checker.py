#!/usr/bin/env python3

from __future__ import division
from argparse import ArgumentParser
from email.message import EmailMessage

import json, subprocess, smtplib, sys


def sizeof_fmt(num, suffix='B'):
    for unit in ['','Ki','Mi','Gi','Ti','Pi','Ei','Zi']:
        if abs(num) < 1024.0:
            return "%3.1f%s%s" % (num, unit, suffix)
        num /= 1024.0
    return "%.1f%s%s" % (num, 'Yi', suffix)


parser = ArgumentParser()
parser.add_argument('-t','--quota-threshold', required=False, type=int, default=90,
                    help="Quota threshold above which alarm is raised")
parser.add_argument('-q','--include-quota-disabled', required=False, action='store_true',
                    help="Include in the report users for which no quota limit is enforced")
parser.add_argument('-d','--display-only', required=False, action='store_true',
                    help="Show report on screen without sending the email")
parser.add_argument('-r', '--recipient', required=False, default='ceph-botmail@cern.ch',
                    help="Recipient email address")
parser.add_argument('-s', '--sender', required=False, default='root@cephadm.cern.ch',
                    help="Sender email address")
parser.add_argument('-c','--cluster', required=False,
                    help="Cluster name for email subject")
args = parser.parse_args();


out = ""
users = json.loads(subprocess.getoutput('radosgw-admin user list'))
for uid in users:
    try:
        info = json.loads(subprocess.getoutput('radosgw-admin user info --uid=%s' % (uid.strip('\n'))))
        if (info['user_quota']['max_size_kb'] > 1):
            if (info['user_quota']['enabled']):
                try:
                    stats = json.loads(subprocess.getoutput('radosgw-admin user stats --uid=%s' % (uid.strip('\n'))))['stats']
                except:
                    stats = {}
                    stats['total_bytes'] = 0
                    stats['total_entries'] = 0
                percentused = 100*stats['total_bytes']/info['user_quota']['max_size'];
                if percentused > args.quota_threshold:
                    out+=("Account %s (%s) is reaching its quota (%.2f)%s\n" % (uid.strip('\n'), info['display_name'], percentused, (', please contact '+info['email']) if info['email'] != '' else '')) #, info['email'] if info['email'] != '' else 'none' )
            elif args.include_quota_disabled and not (info['user_quota']['enabled']):
                out += ('Account %s (%s) has %s kb of quota but quota is disabled!\n' % (uid.strip('\n'), info['display_name'], info['user_quota']['max_size_kb']))
    except:
        print("Warning: User %s does not exist but it part of users list" % (uid))


if out != "":
  if (args.display_only):
    print (out)
  else:
    subject = "S3 Quota checker report"
    if args.cluster:
      subject = "S3 Quota checker report for "+args.cluster

    msg = EmailMessage();
    msg['Subject'] = subject
    msg['From'] = args.sender
    msg['To'] = args.recipient
    msg.set_content(out)
    
    s = smtplib.SMTP('localhost')
    s.send_message(msg)
    s.quit()

