#!/usr/bin/python3 -u

from __future__ import division

import json, subprocess, smtplib, sys


def sizeof_fmt(num, suffix='B'):
    for unit in ['','Ki','Mi','Gi','Ti','Pi','Ei','Zi']:
        if abs(num) < 1024.0:
            return "%3.1f%s%s" % (num, unit, suffix)
        num /= 1024.0
    return "%.1f%s%s" % (num, 'Yi', suffix)

users = sys.stdin.readlines(); # json.loads(subprocess.getoutput('radosgw-admin --cluster=gabe user list'))

for uid in users:
    info = json.loads(subprocess.getoutput('radosgw-admin --cluster=gabe user info --uid=%s' % uid.strip('\n')))
    if info['user_quota']['max_size_kb'] > 1:
        try:
            stats = json.loads(subprocess.getoutput('radosgw-admin --cluster=gabe user stats --uid=%s --sync-stats' % uid.strip('\n')))['stats']
        except:
            stats = {}
            stats['size_actual'] = 0
            stats['num_objects'] = 0

        buckets = json.loads(subprocess.getoutput('radosgw-admin --cluster=gabe bucket list --uid=%s' % uid.strip('\n')))
        percentused = 100*stats['size_actual']/info['user_quota']['max_size'];

        print("%s (%s): %s quota, %s used, %.2f percent full,  %d buckets, %d objects, %d raw_quota, %d raw_used, " % (info['display_name'], uid.strip('\n'), sizeof_fmt(info['user_quota']['max_size']), sizeof_fmt(stats['size_actual']), percentused, len(buckets), stats['num_objects'], info['user_quota']['max_size'], stats['size_actual'])) #, info['email'] if info['email'] != '' else 'none' )
