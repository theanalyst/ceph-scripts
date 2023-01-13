#!/usr/bin/env python3

import argparse
import gzip
import json
import os
import subprocess
import sys
import time


def get_json(command):
  response = subprocess.run(command, shell=True, check=True, stdout=subprocess.PIPE)
  return json.loads(response.stdout)

def load_json(fpath):
  try:
    with gzip.open(fpath, 'r') as f:
      return json.load(f)
  except OSError:
    with open(fpath, 'r') as f:
      return json.load(f)

def load_subvols(content):
  subvols = {}
  for k, v in content.items():
    subvols[k] = Subvolume(v["uid"], v["gid"], v["mode"], v["path"])
  return subvols


def get_fss(cluster):
  return get_json(f"ceph --cluster {cluster} fs ls -f json")

def get_volumes(cluster):
  return get_json(f"ceph --cluster {cluster} fs volume ls -f json")

def get_subvolumes(cluster, volume):
  return get_json(f"ceph --cluster {cluster} fs subvolume ls {volume} -f json")

def get_subvolume_info(cluster, volume, subvolume):
  return get_json(f"ceph --cluster {cluster} fs subvolume info {volume} {subvolume} -f json")

def decimal_to_octal(decimal):
  try:
    octal = oct(decimal)
    return octal
  except ValueError:
    raise VolumeException(-errno.EINVAL, "Invalid mode '{0}'".format(mode))

class Subvolume:
  def __init__(self, uid, gid, mode, path):
    self.uid = uid
    self.gid = gid
    self.mode = mode
    self.path = path

  def print(self):
    print (self.__dict__)

  def build_full_path(self, mount=None):
    if mount:
      # `os.path.join` does not work because `/volumes/_nogroup/...` is considered an absolute path
      fpath = mount + "/" + self.path
      return os.path.normpath(fpath)
    else:
      return self.path

  def same_owner(self, subvol):
    assert(self.path == subvol.path)
    if self.uid != subvol.uid:
      return False
    if self.gid != subvol.gid:
      return False
    return True

  def fix_owner(self, mount=None):
    path = self.build_full_path(mount)
    print ("chown %s:%s %s" % (self.uid, self.gid, path))

  def same_mode(self, subvol):
    assert(self.path == subvol.path)
    if self.mode != subvol.mode:
      return False
    return True

  def fix_mode(self, mount=None):
    path = self.build_full_path(mount)
    # `fs subvolume info` returns mode in decimal -- get back to octal
    octal = decimal_to_octal(self.mode)
    # The mode should be for file type directory, i.e., starts with 40 (see `man stat`)
    assert(octal.startswith("0o40"))
    print ("chmod %s %s" % (octal[4:], path))


if __name__ == "__main__":
  parser = argparse.ArgumentParser(description="CephFS Subvolume Dump")
  parser.add_argument("-c", "--cluster", help="Cluster name", required=True, default=None)
  parser.add_argument("-i", "--input", help="File containing previous dump to restore to", required=True)
  parser.add_argument("-m", "--mount", help="Local mountpoint to manipulate subvolume attributes")
  parser.add_argument("-n", "--list-new", help="Print list of subvolumes for which historic data is unknown", default=False, action="store_true")
  args = parser.parse_args()

  # Load the json file with the previous dump
  old_json = load_json(args.input)
  old_subvols = load_subvols(old_json)

  # Get the current properties of each subvolume and compare
  new = []
  subvolumes = get_subvolumes(args.cluster, "cephfs")
  for subvol in subvolumes:
    subvol_name = subvol["name"]
    if subvol_name in old_subvols.keys():
      info = get_subvolume_info(args.cluster, "cephfs", subvol_name)
      subvol = Subvolume(info["uid"], info["gid"], info ["mode"], info["path"])

      if not old_subvols[subvol_name].same_owner(subvol):
        old_subvols[subvol_name].fix_owner(mount=args.mount)

      if not old_subvols[subvol_name].same_mode(subvol):
        old_subvols[subvol_name].fix_mode(mount=args.mount)
    else:
      new.append(subvol_name)

  if args.list_new:
    print ("List of snapshots for historic data is unknown:")
    print ('\n'.join(new))

