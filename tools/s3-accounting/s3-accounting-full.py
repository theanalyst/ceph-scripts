#!/usr/bin/python -u

import json, commands, ldap



def sizeof_fmt(num, suffix='B'):
    for unit in ['','Ki','Mi','Gi','Ti','Pi','Ei','Zi']:
        if abs(num) < 1024.0:
            return "%3.1f%s%s" % (num, unit, suffix)
        num /= 1024.0
    return "%.1f%s%s" % (num, 'Yi', suffix)



users = json.loads(commands.getoutput('radosgw-admin --cluster=gabe user list'))

for uid in users:
    info = json.loads(commands.getoutput('radosgw-admin --cluster=gabe user info --uid=%s' % uid))
    if info['user_quota']['max_size_kb'] > 1:
        try:
            stats = json.loads(commands.getoutput('radosgw-admin --cluster=gabe user stats --uid=%s' % uid))['stats']
        except:
            stats = {}
            stats['total_bytes'] = 0
            stats['total_entries'] = 0

        buckets = json.loads(commands.getoutput('radosgw-admin --cluster=gabe bucket list --uid=%s' % uid))

        print '%s (%s): %s quota, %s used, %d buckets, %d objects, %s' % (info['display_name'], uid, sizeof_fmt(info['user_quota']['max_size']), sizeof_fmt(stats['total_bytes']), len(buckets), stats['total_entries'], info['email'])

