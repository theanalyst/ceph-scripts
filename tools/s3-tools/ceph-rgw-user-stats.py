#!/usr/bin/env python3

from argparse import ArgumentParser
import json, re, socket, subprocess, time

import sys

# Carbon servers for reporting
SERVERS = [
  ('filer-carbon.cern.ch', 2003),
  ('cephmonitd.cern.ch', 2003)
]


report_usage_template = "ceph.%s.s3_usage.%s.%s.%s %s %s"
rm_symbols = re.compile(r"[^a-zA-Z0-9]+")


# Parse options
parser = ArgumentParser(description="CERN Ceph S3 Users usage to Graphite")
parser.add_argument("-c", "--cluster", required=True,
                    help="Cluster name (beesly, nethub, ...)")
args = parser.parse_args();
cluster=args.cluster


# Helper function to send to carbon cache
def send(line):
    for s, p in SERVERS:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.connect((socket.gethostbyname(s), p))
        sock.send(line+'\n')
        sock.close()


# Get the list of local users
user_list = json.loads(subprocess.getoutput('radosgw-admin user list'))

# Scan all the users first
for user in user_list:
    timestamp = int(time.time())
    try:
        res = json.loads(subprocess.getoutput("timeout 7140 radosgw-admin user stats --uid=%s" % (user)))
    except:
        continue
    for metric, value in res["stats"].items():
        data = report_usage_template % (cluster, 'user', rm_symbols.sub("_", user), metric, value, timestamp)
        send(data)

if cluster == "gabe":
    user_list.remove('rvalverd') # Remove rvalverd
    user_list.append('rvalverd') # Put rvalverd at the end (in case we have time)

# Scan the buckets now
for user in user_list:
    timestamp = int(time.time())
    try:
        res = json.loads(subprocess.getoutput("timeout 7140 radosgw-admin bucket stats --uid=%s" % (user)))
    except:
        continue
    for bucket in res:
        bucket_name = bucket["bucket"]
        if "rgw.main" in bucket["usage"]:
            for metric, value in bucket["usage"]["rgw.main"].items():
                data = report_usage_template % (cluster, 'bucket', rm_symbols.sub("_", bucket_name), metric, value, timestamp)
                send(data)

