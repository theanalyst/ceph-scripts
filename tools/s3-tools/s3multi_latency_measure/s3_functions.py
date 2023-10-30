import boto3
import botocore
import warnings
import random
from hashlib import sha256
warnings.simplefilter("ignore")  # s3_make connection has a ssl cert warning that occurs constantly, this hides it.

#instance a https connection to the specified host using supplied keypair
def s3_make_connection(hostname, access_key, secret_key):
    print(f'opening connection to {hostname}')
    try:
        return boto3.resource('s3',
                              endpoint_url=str(hostname),
                              aws_access_key_id=access_key,
                              aws_secret_access_key=secret_key,
                              verify=False,  # toggles  ssl cert validation, cern uses self signed from their own CA and python / ssl lib doesn't know that.
                              use_ssl=True) 
    except botocore.exceptions.EndpointConnectionError:
        print(f"Unable to connect to {hostname} - check keys and connection.")
        exit()


#print a list of all buckets availible with a given connection
def s3_print_buckets(connection, hostname="host"):
    try:
        print(f"{hostname} buckets:")
        for bucket in connection.buckets.all():
            print(bucket.name)
    except botocore.exceptions.EndpointConnectionError:
        print(f"Connection to {connection} lost while fetching bucket list.")
        exit()


#fetch a bucket from a connection so you can operate on it
def s3_fetch_bucket(connection, bucket_name, hostname="host"):    
    bucket = connection.Bucket(bucket_name)
    try:
        connection.meta.client.head_bucket(Bucket=bucket_name)
        return(bucket)
    except botocore.exceptions.ClientError as e:  # If a client error is thrown, then check that it was a 404 error.
        if e.response['Error']['Code'] == '404': # If it was a 404 error, then the bucket does not exist.
            return(None)
        if e.response['Error']['Code'] == '403':
            print("Keypair invalid or has insufficent perms for this bucket.")
            exit()


#create a new bucket on a connection given no other bucker with that name exists
def s3_add_bucket(connection, bucket_name, hostname="host"):
    try:
        connection.meta.client.head_bucket(Bucket=bucket_name)
        print(f"bucket {bucket_name} allready exists on {hostname}")
    except botocore.exceptions.ClientError as e: 
        if e.response['Error']['Code'] == "404":  # If it was a 404 error, then the bucket does not exist and we can create it!
            print(f"bucket name is valid.")
            choice = input(f"confirm creation of bucket {bucket_name} on {hostname}? (YES): ")
            if choice == 'YES':
                return connection.create_bucket(Bucket=f'{bucket_name}')
            else:
                print("cancelling creation")


#wipe or delete a bucket a connection has access to given the bucket exists
def s3_del_bucket(connection, bucket_name, hostname="host", wipe=True):
    bucket = s3_fetch_bucket(connection, bucket_name, hostname)  # did we fetch a valid bucket to delete?
    if bucket is not None:
        for obj in bucket.objects.all():
            print(f"deleting {obj.key}")
            obj.delete()
        if not wipe:
            choice = input(f"confirm DELETION of bucket {bucket_name} on {hostname}? (YES): ")            
            if choice == 'YES':
                bucket.delete()
            else:
                print('cancelling deletion.')
    else:
        print(f'{bucket_name} does not exist on {hostname} and cannot be deleted.')



def s3_print_objects(connection, bucket, hostname="host"):
    print(f"{hostname} objects [{bucket.name}]:")
    for object in bucket.objects.all():
        print(object.key)

#A function that can check for the existance of an object quickly (load) or fetch the whole object (get) from a supplied bucket object /do a http HEAD instead.
def s3_find_object(connection, bucket, key, method):
    try:
        if method == "head": 
            connection.Object(bucket, key).load() # fetch object header (annoyingly only clients have a direct method for this)
            return(True)
        elif method == "get": 
            return connection.Object(bucket, key).get() # get the entire object.
        else: 
            print(f"s3_get_object invalid method \"{method}\"")
            exit()
    except botocore.exceptions.ClientError as e:
        if e.response['Error']['Code'] == "404":
            return(None)
        else:
            print(f"{e.response['Error']['Code']} occured in s3_find_object")


# add a new object to a bucket object given it doesn't allready exist
def s3_add_object(connection, bucket_name, body_size=bytes(4096)):
    obj = connection.Object(f'{bucket_name}', f'{sha256(body_size).hexdigest()}')
    result = obj.put(Body=body_size)
    response = result.get('ResponseMetadata')
    if response.get('HTTPStatusCode') == 200:
        print(f'created new object {obj.key}')
        return(obj.key)
    else:
        print('object Not Uploaded')


# delete an object from a bucket object given it exists
def s3_del_object(connection, bucket_name, key):
    obj = connection.Object(bucket_name, key)
    obj.delete()
    print(f"deleted object {key}")

