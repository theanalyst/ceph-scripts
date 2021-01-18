#!/bin/bash

# Create and activate a swapfile sized 2x RAystem.total_bytes

if [ -f /swapfile ]
then
    echo "/swapfile already exists! exiting..."
    exit 1
fi

MEM=`cat /proc/meminfo  | grep MemTotal | awk '{print $2}'`
DF=`df -Pk / | grep -v Filesystem | awk '{print $4}'`

SIZE=$(( $MEM * 2 ))

if [ "$DF" -le "$SIZE" ];
then
    echo "Insufficient free space to create /swapfile"
    exit 1
fi

echo dd if=/dev/zero of=/swapfile bs=1M count=$((SIZE / 1024))
echo chmod 600 /swapfile
echo mkswap /swapfile
echo swapon /swapfile
echo "echo /swapfile swap swap defaults 0 0 >> /etc/fstab"


echo
read -p "Continue with above? (y/n) " choice
case "$choice" in 
  y|Y ) echo "continuing...";;
  n|N ) echo "no" && exit 1;;
  * ) echo "invalid" && exit 1;;
esac

dd if=/dev/zero of=/swapfile bs=1M count=$((SIZE / 1024))
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo /swapfile swap swap defaults 0 0 >> /etc/fstab
