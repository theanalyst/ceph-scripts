#!/usr/bin/env python3

import json
import statistics
import subprocess

ceph_osd_perf = subprocess.run(['ceph', 'osd', 'perf', '-f', 'json'], stdout=subprocess.PIPE)
perf_json = ceph_osd_perf.stdout
perf = json.loads(perf_json)['osdstats']['osd_perf_infos']

# {"id":38,"perf_stats":{"commit_latency_ms":0,"apply_latency_ms":0,"commit_latency_ns":0,"apply_latency_ns":0}}

cls = [p['perf_stats']['commit_latency_ms'] for p in perf if p['perf_stats']['commit_latency_ms'] > 0]

mean_cl = statistics.mean(cls)
stdev_cl = statistics.stdev(cls)
print('Mean Commit Latency: %.3f' % mean_cl)
print('Std Commit Latency: %.3f' % stdev_cl)

for osd in perf:
    id = osd['id']
    cl = osd['perf_stats']['commit_latency_ms']
    if cl > mean_cl + 5*stdev_cl:
        print('osd.%d' % id, 'has high commit latency: %.3f ms' % cl)
