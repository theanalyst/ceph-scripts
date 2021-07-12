#!/bin/bash

FILTER=""
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -p|--peered) FILTER="peered" ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

ceph pg ls undersized 2>/dev/null | grep undersized | grep ${FILTER} | awk '{print $1}' | xargs -n1 echo ceph pg repeer
