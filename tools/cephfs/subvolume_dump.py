#!/usr/bin/env python3

import argparse
import datetime
import gzip
import json
import os
import subprocess

def get_json(command):
  response = subprocess.run(command, shell=True, check=True, stdout=subprocess.PIPE)
  return json.loads(response.stdout)

def get_fss(cluster):
  return get_json(f"ceph --cluster {cluster} fs ls -f json")

def get_volumes(cluster):
  return get_json(f"ceph --cluster {cluster} fs volume ls -f json")

def get_subvolumes(cluster, volume):
  return get_json(f"ceph --cluster {cluster} fs subvolume ls {volume} -f json")

def get_subvolume_info(cluster, volume, subvolume):
  return get_json(f"ceph --cluster {cluster} fs subvolume info {volume} {subvolume} -f json")

def write_file(cluster, path, fname, content, gz=False):
  today = datetime.datetime.today()
  date = today.strftime('%Y_%m_%d')
  time = today.strftime('%H_%M')

  outpath = os.path.join(path, cluster, date)
  outfile = os.path.join(outpath, time+"_"+fname)
  os.makedirs(outpath, exist_ok=True)
  if gz:
    with gzip.open(outfile, 'wt') as fout:
      fout.write(content)
  else:
    with open(args.output, 'wt') as fout:
      fout.write(content)
  return


if __name__ == "__main__":
  parser = argparse.ArgumentParser(description="CephFS Subvolume Dump")
  parser.add_argument("-c", "--cluster", help="Cluster name", required=True, default=None)
  parser.add_argument("-o", "--output", help="Output directory where to write the subvolume dump", default="/mnt/projectspace/backup")
  parser.add_argument("-d", "--debug", help="Do not write json file, use stdout instead", action="store_true", default=False)
  args = parser.parse_args()

  # Get the subvolumes
  #   let's assume one volume only named "cephfs" for now
  subvolumes = get_subvolumes(args.cluster, "cephfs")

  # Get the properties of each subvolume
  subovolumes_info = {}
  for subvol in subvolumes:
    subvol_name = subvol["name"]
    subovolumes_info[subvol_name] = get_subvolume_info(args.cluster, "cephfs", subvol_name)

  # Prepare json output
  json_output = json.dumps(subovolumes_info)

  # Print to stdout or file
  if args.debug:
    print (json_output)
  else:
    write_file(args.cluster, args.output, "subvolume_dump.gz", json_output, gz=True)

