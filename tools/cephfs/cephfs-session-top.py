#!/usr/bin/env python3

import argparse
import json
import os
import re
import subprocess
import sys

#
# Global
#

cmd_description='print cephfs session top list'

parser = argparse.ArgumentParser(prog='cephfs-session-top', description=cmd_description)
parser.add_argument(
    '-m', '--mds',
    metavar='name',
    help='show for this MDS only',
    required=False,
)
parser.add_argument(
    '-F', '--fs',
    metavar='cephfs',
    help='show for this fs only',
    required=False,
    default='',
)
parser.add_argument(
    '-f', '--file',
    metavar='file',
    help='process session list from file',
    action='append',
    required=False,
)
parser.add_argument(
    '-N', '--top',
    metavar='n',
    type=int,
    help='show firs N sessions only (default: %(default)s)',
    required=False,
    default=100,
)
parser.add_argument(
    '-s', '--sort-by',
    metavar='loadavg|numcaps|reccaps|relcaps|liveness|capacqu|host|root|count',
    help='sort by specified field (default: %(default)s)',
    default='loadavg',
    required=False,
)
parser.add_argument(
    '-H', '--filter-by-host',
    metavar='hostname',
    help='show sessions for this hostname only',
    required=False,
)
parser.add_argument(
    '-X', '--filter-by-host-regexp',
    metavar='regexp',
    help='show sessions from hosts matching this regexp',
    required=False,
)
parser.add_argument(
    '-r', '--filter-by-root',
    metavar='root',
    help='show sessions for this root only',
    required=False,
)
parser.add_argument(
    '-R', '--filter-by-root-regexp',
    metavar='regexp',
    help='show sessions with roots matching this regexp',
    required=False,
)
parser.add_argument(
    '-g', '--group-by-host',
    help='group sessions by hostname',
    action='store_true',
    default=False,
)
parser.add_argument(
    '-G', '--group-by-root',
    help='group sessions by root',
    action='store_true',
    default=False,
)

#
# Functions
#

def top(mds, N, sort_by, filter_by_host, filter_by_host_regexp, filter_by_root,
        filter_by_root_regexp, group_by_host, group_by_root):

    if mds.get('file'):
        print(f'File: {os.path.basename(mds["file"])}')

        if mds['file'] == '-':
            sessions = json.load(sys.stdin)
        else:
            with open(mds['file'], 'r') as f:
                sessions = json.load(f)
    else:
        print(f'MDS: {mds["name"]}')
        print(f'Rank: {mds["rank"]}')

        daemon = f'mds.{mds["name"]}'
        result = subprocess.run(['ceph', 'tell', daemon, 'session', 'ls'],
                                stdout=subprocess.PIPE,
                                stderr=subprocess.PIPE,
                                universal_newlines=True)
        if result.returncode != 0:
            print(
                f'ceph tell {daemon} session ls failed: {result.stderr}',
                file=sys.stderr
            )
            exit(1)

        sessions = json.loads(result.stdout)

    print(f'Client Sessions: {len(sessions)}')
    print()

    if not sessions:
        return

    if filter_by_host:
        sessions = [
            s for s in sessions \
                if s.get('client_metadata',
                         {'hostname': ''})['hostname'] == filter_by_host
        ]

    if filter_by_host_regexp:
        sessions = [
            s for s in sessions \
                if filter_by_host_regexp.search(
                    s.get('client_metadata',
                          {'hostname': ''})['hostname']
                )
        ]

    if filter_by_root:
        sessions = [
            s for s in sessions \
                if s.get('client_metadata',
                         {'root': ''})['root'] == filter_by_root
        ]

    if filter_by_root_regexp:
        sessions = [
            s for s in sessions \
                if filter_by_root_regexp.search(
                    s.get('client_metadata',
                          {'root': ''})['root']
                )
        ]

    if group_by_host:
        groups = {}
        for s in sessions:
            host = s.get('client_metadata', {'hostname': '--'})['hostname']
            if host not in groups:
                groups[host] = []
            groups[host].append(s)
        sessions = []
        for host, group in groups.items():
            session = {
                'count' : len(group),
                'hostname' : host,
                'request_load_avg' : 0,
                'num_caps' : 0,
                'recall_caps' : {'value': 0},
                'release_caps' : {'value': 0},
                'session_cache_liveness' : {'value': 0},
                'cap_acquisition' : {'value': 0},
            }
            
            for s in group:
                session['request_load_avg'] += s.get('request_load_avg', 0)
                session['num_caps'] += s.get('num_caps', 0)
                session['recall_caps']['value'] += \
                    s.get('recall_caps', {'value': 0})['value']
                session['release_caps']['value'] += \
                    s.get('release_caps', {'value': 0})['value']
                session['session_cache_liveness']['value'] += \
                    s.get('session_cache_liveness', {'value': 0})['value']
                session['cap_acquisition']['value'] += \
                    s.get('cap_acquisition', {'value': 0})['value']
            sessions.append(session)

    if group_by_root:
        groups = {}
        for s in sessions:
            root = s.get('client_metadata', {'root': '--'})['root']
            if root not in groups:
                groups[root] = []
            groups[root].append(s)
        sessions = []
        for root, group in groups.items():
            session = {
                'count' : len(group),
                'root' : root,
                'request_load_avg' : 0,
                'num_caps' : 0,
                'recall_caps' : {'value': 0},
                'release_caps' : {'value': 0},
                'session_cache_liveness' : {'value': 0},
                'cap_acquisition' : {'value': 0},
            }
            
            for s in group:
                session['request_load_avg'] += s.get('request_load_avg', 0)
                session['num_caps'] += s.get('num_caps', 0)
                session['recall_caps']['value'] += \
                    s.get('recall_caps', {'value': 0})['value']
                session['release_caps']['value'] += \
                    s.get('release_caps', {'value': 0})['value']
                session['session_cache_liveness']['value'] += \
                    s.get('session_cache_liveness', {'value': 0})['value']
                session['cap_acquisition']['value'] += \
                    s.get('cap_acquisition', {'value': 0})['value']
            sessions.append(session)

    if sort_by.lower() == 'loadavg':
        sessions.sort(
            key=lambda s: s.get('request_load_avg', 0),
            reverse=True
        )
    elif sort_by.lower() == 'numcaps':
        sessions.sort(
            key=lambda s: s.get('num_caps', 0),
            reverse=True
        )
    elif sort_by.lower() == 'reccaps':
        sessions.sort(
            key=lambda s: s.get('recall_caps', {'value': 0})['value'],
            reverse=True
        )
    elif sort_by.lower() == 'relcaps':
        sessions.sort(
            key=lambda s: s.get('release_caps', {'value': 0})['value'],
            reverse=True
        )
    elif sort_by.lower() == 'liveness':
        sessions.sort(
            key=lambda s: s.get('session_cache_liveness', {'value': 0})['value'],
            reverse=True
        )
    elif sort_by.lower() == 'capacqu':
        sessions.sort(
            key=lambda s: s.get('cap_acquisition', {'value': 0})['value'],
            reverse=True
        )
    elif sort_by.lower() == 'host':
        sessions.sort(
            key=lambda s: s.get('client_metadata',
                                {'hostname': '--'})['hostname']
        )
    elif sort_by.lower() == 'root':
        sessions.sort(
            key=lambda s: s.get('client_metadata', {'root': '--'})['root']
        )
    elif sort_by.lower() == 'count':
        assert group_by_host or group_by_root
        sessions.sort(
            key=lambda s: s['count'],
            reverse=True
        )
    else:
        print(f'invalid sort_by: {sort_by}', file=sys.stderr)
        exit(1)

    if N:
        sessions = sessions[:N]

    print('LOADAVG NUMCAPS RECCAPS RELCAPS LIVENESS CAPACQU', end=' ')
    if group_by_host:
        print('COUNT HOST')
    elif group_by_root:
        print('COUNT ROOT')
    else:
        print('CLIENT')

    for s in sessions:
        print(
            f'{s.get("request_load_avg", 0):7} '
            f'{s.get("num_caps", 0):7} '
            f'{int(s.get("recall_caps", {"value": 0})["value"]):7} '
            f'{int(s.get("release_caps", {"value": 0})["value"]):7} '
            f'{int(s.get("session_cache_liveness", {"value": 0})["value"]):8} '
            f'{int(s.get("cap_acquisition", {"value": 0})["value"]):7} ',
            end=''
        )
        if group_by_host:
            print(f'{s["count"]:5} {s["hostname"]}')
        elif group_by_root:
            print(f'{s["count"]:5} {s["root"]}')
        else:
            print(
                f'{s["id"]} '
                f'{s.get("client_metadata", {"hostname": "--"})["hostname"]}:'
                f'{s.get("client_metadata", {"root": "--"})["root"]}'
            )

def main():
    args = parser.parse_args()

    filter_by_host_regexp = None
    if args.filter_by_host_regexp:
        try:
            filter_by_host_regexp = re.compile(args.filter_by_host_regexp)
        except re.error as e:
            print(f'invalid filter-by-host-regexp: {e}', file=sys.stderr)
            exit(1)

    filter_by_root_regexp = None
    if args.filter_by_root_regexp:
        try:
            filter_by_root_regexp = re.compile(args.filter_by_root_regexp)
        except re.error as e:
            print(f'invalid filter-by-root-regexp: {e}', file=sys.stderr)
            exit(1)

    if args.group_by_host and args.group_by_root:
        print(
            '--group-by-host and --group-by-root cannot be specified together',
            file=sys.stderr
        )
        exit(1)

    if args.sort_by.lower() == 'count' and \
       not args.group_by_host and not args.group_by_root:
        print(
            'sort by count is only valid with --group-by options',
            file=sys.stderr
        )
        exit(1)

    mds = []

    if args.file:
        if args.mds or args.fs:
            print(
                'File and --mds/--fs cannot be specified together',
                file=sys.stderr
            )
            exit(1)

        for f in args.file:
            if f != '-' and not os.path.exists(f):
                print(f'file not found: {f}', file=sys.stderr)
                exit(1)
            mds.append({'file': f})
    elif args.mds and args.fs:
        print(
            'Either --mds or --fs can be specified, not both',
            file=sys.stderr
        )
        exit(1)
    else:
        result = subprocess.run(
            ['ceph', 'fs', 'status', args.fs, '--format', 'json'],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=True
        )
        if result.returncode != 0:
            print(f'ceph fs status failed: {result.stderr}', file=sys.stderr)
            exit(1)

        fs_status = json.loads(result.stdout)
        for m in fs_status['mdsmap']:
            if args.mds:
                if m['name'] == args.mds:
                    mds.append(m)
                    break
                continue
            if m['state'] == 'active':
                mds.append(m)

    if not mds:
        print(f'no active MDS found', file=sys.stderr)
        exit(1)

    for m in mds:
        top(m, args.top, args.sort_by, args.filter_by_host,
            filter_by_host_regexp, args.filter_by_root, filter_by_root_regexp,
            args.group_by_host, args.group_by_root)

#
# main
#

main()
