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
parser.add_argument('-s', '--sender', required=True,
                    help="Value for 'From' header (required)")
parser.add_argument('-c','--cluster', required=True,
                    help="Cluster name (required)")

args = parser.parse_args();
users = json.loads(subprocess.getoutput('radosgw-admin --cluster=%s user list' % (args.cluster)))
out = ""

for uid in users:
    try:
        info = json.loads(subprocess.getoutput('radosgw-admin --cluster=%s user info --uid=%s' % (args.cluster, uid.strip('\n'))))
        if (info['user_quota']['max_size_kb'] > 1) and (info['user_quota']['enabled']):
            try:
                stats = json.loads(subprocess.getoutput('radosgw-admin --cluster=%s user stats --uid=%s' % (args.cluster, uid.strip('\n'))))['stats']
            except:
                stats = {}
                stats['total_bytes'] = 0
                stats['total_entries'] = 0

            percentused = 100*stats['total_bytes']/info['user_quota']['max_size'];

            if percentused > 95:
                out+=("Account %s (%s) is reaching its quota (%.2f)%s\n" % (uid.strip('\n'), info['display_name'], percentused, (', please contact '+info['email']) if info['email'] != '' else '')) #, info['email'] if info['email'] != '' else 'none' )
        elif (info['user_quota']['max_size_kb'] > 1) and !(info['user_quota']['enabled']):
            out += 'Account %s (%s) has %s quota but quota is disabled!\n' % ((uid.strip('\n'), info['display_name'], info['user_quota']['max_size_kb'])
    except:
        print(uid)

if out != "": 
  msg = EmailMessage();
  msg['Subject'] = "S3 Quota checker report for "+args.cluster
  msg['From'] = args.sender
#  msg['To'] = "ceph-admins@cern.ch"
  msg['To'] = "julien.collet@cern.ch"
  msg.set_content(out)
  
  s = smtplib.SMTP('localhost')
  s.send_message(msg)
  s.quit()

