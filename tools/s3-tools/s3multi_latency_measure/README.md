## s3multi_latency_measure

This program can be used to measure the propagation time for object creation/deletion in an S3 multisite deployment.

The program looks for `config.yaml` file (example in dir) containing an s3 keypair.
Default location of the file is `/etc/s3multi_latency_measure/config.yaml`

Basic operation of the program can be considered as bellow:
  - Connect to `endpoint\_a` in zoneA and `endpoint\_b` in zoneB
  - Check for the existance of bucket `X` on both `a` and `b`
  - Create an object through `endpoint\_a`
    - Multisite will replicate zoneA -----> zoneB
  - Poll for obj hit through `endpoint\_b` 
  - Pull the obj through `endpoint\_b`
  - Compare object hashes
  - Delete obj through `endpoint\_b`
    - Multisite will dereplicate zoneB ----> zoneA
  - Perform various time metric measurements during this process and send via plaintext to carbon
