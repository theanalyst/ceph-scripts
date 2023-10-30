import csv

def s3_csv_write(filename, headers, ms_lat, objdl_lat, objdl_time, timestamp, filesize):
    with open(str(filename), 'a+') as csvfile:
        writer = csv.DictWriter(csvfile, delimiter=',', fieldnames=headers)
        try:
            if not csv.Sniffer().has_header(csvfile):
                writer.writeheader()
        except:
             pass
        writer.writerow({"replication_latency": ms_lat,
                         "download_latency": objdl_lat,
                         "download_time": objdl_time,
                         "timestamp": timestamp,
                         "filesize": filesize})

#function that takes in a number for the total length of a bytestring and converts it to Standard units
def sizeof_su(num):
    for unit in ["", "KB", "MB", "GB", "TB", "PB", "EB", "ZB"]:
        if int(num) < 1024.0:
            return f"{num:3.1f}{unit}"
        num /= 1024.0

#function that takes in a num string with a standard unit suffix and converts it to bytes
def sizeof_bytes(filestring):
    units =  ["KB", "MB", "GB", "TB", "PB", "EB", "ZB"] #cant have "", for index 0 here as with above as it hits the bellow if in statement
    if not any(charecter.isdigit() for charecter in filestring):
        print("you have supplied a -f flag that does not contain any numeric value.")
        exit()
    for unit in units: 
        if unit in filestring:
            return int(filestring[:len(filestring)-2]) * 1024 ** (units.index(unit)+1) #return the int typecast of: input (with suffix removed via slice) * 1024 to the power of the index position of the unit + 1
    print("You have supplied a -f flag with an invalid standard unit prefix.")
    exit()

#function that returns a fqdn with or without a https prefix
def validate_hostname(hostname, url=True):
    if url:
        if hostname.startswith('https://'):
            return hostname
        else:
            return 'https://'+hostname
    else:
        return hostname
