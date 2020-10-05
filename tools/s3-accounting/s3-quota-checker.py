#!/usr/bin/python3 -u

from __future__ import division

import json, subprocess, smtplib, sys


def sizeof_fmt(num, suffix='B'):
    for unit in ['','Ki','Mi','Gi','Ti','Pi','Ei','Zi']:
        if abs(num) < 1024.0:
            return "%3.1f%s%s" % (num, unit, suffix)
        num /= 1024.0
    return "%.1f%s%s" % (num, 'Yi', suffix)

users = json.loads(subprocess.getoutput('radosgw-admin user list'))
out = ""
for uid in users:
    try:
        info = json.loads(subprocess.getoutput('radosgw-admin  user info --uid=%s' % uid.strip('\n')))
        if (info['user_quota']['max_size_kb'] > 1) and (info['user_quota']['enabled']):
            try:
                stats = json.loads(subprocess.getoutput('radosgw-admin user stats --uid=%s' % uid.strip('\n')))['stats']
            except:
                stats = {}
                stats['total_bytes'] = 0
                stats['total_entries'] = 0

            percentused = 100*stats['total_bytes']/info['user_quota']['max_size'];

            if percentused > 95:
                out+=("Account %s (%s) is reaching its quota (%.2f)\n" % (uid.strip('\n'), info['display_name'], percentused)) #, info['email'] if info['email'] != '' else 'none' )
    except:
        print(uid)

subprocess.run(stdout=subprocess.PIPE,text=True,input=out)

~                    
