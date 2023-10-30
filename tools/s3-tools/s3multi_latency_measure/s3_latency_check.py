import subprocess, time
import yaml
from argparse import ArgumentParser
from hashlib import sha256
from os import urandom
from timeit import default_timer as timer
from s3_functions import *  # Most of the function for reusable S3 work
from s3_formatting import *  # functions regarding string or data formating used by this program

#this dual setup is messy and unintuitive for a user, but required to use teigi. For now, long term vars are in conf, runtime vars are in args.
# setup arg vars
parser = ArgumentParser(description='A python program for testing the replication latency between two ceph rgw multi-site clusters. It should only be ran on made for purpose test buckets as the program wipes objects and the bucket as part of its operation. This program pulls (and expects) some long term vars from a config file (example in git repo), it looks by default for it at /etc/s3multi_latency_measure/config.yaml')
parser.add_argument('--autonomous', '-A', dest="autonomous", action='store_true', required=False, default=False, help='boolean flag for continuous operation (overrides cycles)')
parser.add_argument('--cycles', '-c', dest='cycles', action='store', required=False, type=int, default=1, help='total number of times you wish to perform the latency test per program run')
parser.add_argument('--object-size', '-f', dest='object_size', action='store', required=True, type=str, help='object size to use (accepts range of 4KB - 10MB with uppercase SU unit suffix)')
parser.add_argument('--config-file', '-C', dest='config_file', action='store', required=False, default='/etc/s3multi_latency_measure/config.yaml', help='config file location to read config from')
parser.add_argument('--poll-rate', '-p', dest='poll_rate', action='store', required=False, type=float,  default=0.5, help='specify a pollrate in seconds (or milliseconds converted up a SU.)')
args = parser.parse_args()

# setup config vars
print(f"trying to read config from {args.config_file}")
try:
    with open(str(args.config_file), "rb") as yfile:
        config = yaml.safe_load(yfile)
except FileNotFoundError:
    print(f"failed to find {args.config_file}, is path correct?")
    exit()

# check the specified file size input by the user and set up our object data payload
data_size = sizeof_bytes(args.object_size)
if data_size > 10785760:  # 10MB in B (with some padding as os.urandom doesn't produce bytestreams that are allways 100% accurate to the supplied value.)
    print(f"supplied object size ({sizeof_su(data_size)}) exceeeds 10MB maximum.")
    exit()
elif data_size < 4096:  # 4KB in B
    print(f"supplied object size ({sizeof_su(data_size)}) does not meet 4KB minimum.")
    exit()


# set up our connections and bucket objects
args.grafana_host = validate_hostname(config['grafana_host'], url=False)
config['endpoint_a'] = validate_hostname(config['endpoint_a'], url=True)
config['endpoint_b'] = validate_hostname(config['endpoint_b'], url=True)
conn_a = s3_make_connection(config['endpoint_a'], config["access_key"], config["secret_key"])
conn_b = s3_make_connection(config['endpoint_b'], config["access_key"], config["secret_key"])
bucket_a = s3_fetch_bucket(conn_a, config['bucket'], config['endpoint_a'])
bucket_b = s3_fetch_bucket(conn_b, config['bucket'], config['endpoint_b'])
print(f"using a object size of {sizeof_su(data_size)}.\n",
      f"Result metrics will be sent to: {config['grafana_host']}:{config['grafana_port']}.")
if bucket_a is None or bucket_b is None:
    print(f"failed to find {config['bucket']} on supplied hosts with supplied keypair.")
    exit()

# create test object(s) in bucket on A and verify it has been created successfully.
def cycle_process():
    data_payload = urandom(data_size)
    put_a_start = timer()
    key = s3_add_object(conn_a, config['bucket'], data_payload)
    obj = s3_find_object(conn_a, config['bucket'], key, "head")
    if obj is None:
        print(f"failed to put object onto {config['endpoint_a']}. connection problem?")
        exit()
    put_a_success = timer()

    # start checking Host B for new object, then download once availible
    while True:
        obj = s3_find_object(conn_b, config['bucket'], key, "head")
        if obj is not None:
            break
        time.sleep(args.poll_rate)
    head_b_success = timer()
    print(f"replication hit for {key}")
    file = s3_find_object(conn_b, config['bucket'], key, "get")
    get_b_success = timer()
    replica_hash = sha256(file['Body'].read()).hexdigest()
    if key == replica_hash: # because the key is a product of hashing the object body, we can compare directly like this
        print(f"object body hash match from [A] {key} to [B] {replica_hash}")  
    else:
        print("object body hash mismatch from [A] {key} to [B] {replica_hash}!")  

    # perform an inverse check for deletion started on b and propagated to a.
    del_b_start = timer()
    s3_del_object(conn_b, config['bucket'], key)
    while True:
        obj = s3_find_object(conn_a, config['bucket'], key, "head")
        if obj is None:
            break
        time.sleep(args.poll_rate)
    head_a_success = timer()
    print(f"dereplication hit for {key}")
    # push our stats for the cycle into filer-carbon or whichever grafana upstream we want
    print(f"Pushing stats to {config['grafana_host']}:{config['grafana_port']} WARNING: this may fail if you are using a version of netcat that doesn't support the -N (EOF) flag!")
    subprocess.run(f"echo test.s3-mu.{args.object_size}.file-upload-time {put_a_success - put_a_start} $(date +%s) | netcat {config['grafana_host']} {config['grafana_port']} -N", shell=True)
    subprocess.run(f"echo test.s3-mu.{args.object_size}.file-replication-latency {head_b_success - put_a_success} $(date +%s) | netcat {config['grafana_host']} {config['grafana_port']} -N", shell=True)
    subprocess.run(f"echo test.s3-mu.{args.object_size}.file-download-time {get_b_success - head_b_success} $(date +%s) | netcat {config['grafana_host']} {config['grafana_port']} -N", shell=True)
    subprocess.run(f"echo test.s3-mu.{args.object_size}.file-dereplication-latency {head_a_success - del_b_start} $(date +%s) | netcat {config['grafana_host']} {config['grafana_port']} -N", shell=True)
    subprocess.run(f"echo test.s3-mu.{args.object_size}.poll-rate {args.poll_rate} $(date +%s) | netcat {config['grafana_host']} {config['grafana_port']} -N", shell=True)


# define two cycle process methods to use and run one based on the supplied flags.
try:
    if args.autonomous:
        print(f"Running infinitely due to autonomous flag.")
        while True:
            cycle_process()
    else:
        print(f"Running for {args.cycles} cycle/s.")
        for cycle in range(0, args.cycles):
            cycle_process()
except KeyboardInterrupt:
    print("Keyboard Interrupt occured, wiping bucket")
    s3_del_bucket(conn_b, config['bucket'], hostname=config['endpoint_a'])
print("fin.")
