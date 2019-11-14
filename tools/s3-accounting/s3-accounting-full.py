#!/usr/bin/python -u

from __future__ import division

import json, commands, ldap, smtplib


src = "root@cephadm.cern.ch"
dst = ["giuliano.colletto@cern.ch"] # must be a list
sub = "S3 user quota treshold exceeded"
server = smtplib.SMTP("localhost")


def sizeof_fmt(num, suffix='B'):
    for unit in ['','Ki','Mi','Gi','Ti','Pi','Ei','Zi']:
        if abs(num) < 1024.0:
            return "%3.1f%s%s" % (num, unit, suffix)
        num /= 1024.0
    return "%.1f%s%s" % (num, 'Yi', suffix)


def sendnotification(uid, userinfo, pu):
    body = """\
From: %s
To: %s
Subject: %s 

Dear Ceph admins, 

User %s (%s,%s) has reached %.2f percent of its quota.
    """ % (src, dst, sub, userinfo['display_name'], uid, userinfo['email'], pu)
    
    server.sendmail(src, dst, body)




users = json.loads(commands.getoutput('radosgw-admin --cluster=gabe user list'))
overquota = {}

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
        percentused = 100*stats['total_bytes']/info['user_quota']['max_size'];

        if percentused > 40:
            overquota[uid] = [info, percentused] 
            # sendnotification(uid, info, percentused)

        print "%s (%s): %s quota, %s used, %.2f percent full,  %d buckets, %d objects, %s," % (info['display_name'], uid, sizeof_fmt(info['user_quota']['max_size']), sizeof_fmt(stats['total_bytes']), percentused, len(buckets), stats['total_entries'], info['email'])



for k in overquota.keys() :
    print overquota[k][0]['user_id']

