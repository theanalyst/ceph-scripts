#!/bin/bash

if [ $# -eq 0 ]; then
    /usr/sbin/selinuxenabled
    echo "/usr/sbin/selinuxenabled reports:" $?
    echo
    echo "Usage: $0 [--mask|--unmask]"
    echo
    exit 0
fi

if [ "$1" == "--mask" ]
then
    echo Linking to /bin/false
    mv -f /usr/sbin/selinuxenabled /usr/sbin/selinuxenabled.orig
    ln -s /bin/false /usr/sbin/selinuxenabled
fi

if [ "$1" == "--unmask" ]
then
    echo Restoring backup /usr/bin/selinuxenabled
    mv -f /usr/sbin/selinuxenabled.orig /usr/bin/selinuxenabled
fi
