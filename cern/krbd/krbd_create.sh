#!/bin/bash

shopt -s extglob


print_help() {
  echo "\

Usage: ./$(basename "$0") --pool <pool> --namespace <namespace> --client <client_id> --size <size>

with:
- pool:         osd pool where to store the RBD image
- namespace:    namespace of the RBD image
- client_id:    name of the client for the cephx keyring                     
- size:         size of the image
"
}


while test $# -gt 0;
do
  case "$1" in
    -h|--help)
      print_help
      exit 0
      ;;
    -p|--pool)
      shift
      case "$1" in
        [a-z]*)
          POOL=$1
          ;;
        *)
          echo "After -p (--pool), $1 doesn't look like a valid pool name."
          ;;
        esac
      ;;
    -n|--namespace)
      shift
      case "$1" in
        [a-z]*)
          NAMESPACE=$1
          ;;
        *)
          echo "After -n (--namespace), $1 doesn't look like a valid name."
          ;;
        esac
      ;;
    -c|--client)
      shift
      case $1 in
        [a-z]*)
          CLIENT_ID=$1
          ;;
        *)
          echo "After -n (--namespace), $1 doesn't look like a valid client name."
          ;;
        esac
      ;;
    -s|--size)
      shift
      case "$1" in
        +([0-9])[M,G,T])
          SIZE=$1
          ;;
        *)
          echo "After -s (--size), $1 doesn't look like a size (e.g., 50G, 1T)."
      esac
      ;;
  esac
  shift
done


# Make sure relevant parameters are set
if [[ -z $POOL || -z $NAMESPACE || -z $CLIENT_ID || -z $SIZE ]]; then
  echo "Error: Invalid input"
  print_help
  exit 1
fi

# Check the namespace
NAMESPACE_CREATE=false
if rbd --pool $POOL namespace ls | grep -q $NAMESPACE; then
  echo "Warning: Namespace $NAMESPACE already exists"
else
  NAMESPACE_CREATE=true
fi

# Check the auth key for the client
KEYRING_CREATE=false
if ceph auth ls 2>/dev/null | grep -q ^client.$CLIENT_ID; then
  echo "Warning: Keyring for client $CLIENT_ID already exists"
else
  KEYRING_CREATE=true
fi

# Check the RBD image
#   The RBD_IMAGE is given by uuidgen. It is very much impossible to have conflicting names, but we check anyway
RBD_IMAGE=$(uuidgen)
RBD_CREATE=false
if $NAMESPACE_CREATE; then
  RBD_CREATE=true
else
  if rbd --pool $POOL --namespace $NAMESPACE ls | grep -q $RBD_IMAGE; then
    echo "Warning: RBD image $RBD_IMAGE already exists"
  else
    RBD_CREATE=true
  fi
fi
echo ""
echo "You are about to create:"
echo "  - RBD image: $RBD_IMAGE in namespace $NAMESPACE (pool $POOL)"
echo "  - Client accessing the namespace: $CLIENT_ID"


echo ""
echo "To proceed with creation, check and execute these commands:"
if $NAMESPACE_CREATE; then
  echo "  rbd --pool $POOL namespace create --namespace $NAMESPACE"
fi
if $KEYRING_CREATE; then
  echo "  ceph auth get-or-create client.$CLIENT_ID mon 'profile rbd' osd 'profile rbd pool=$POOL namespace=$NAMESPACE'"
fi
if $RBD_CREATE; then
  echo "  rbd --pool $POOL --namespace $NAMESPACE create $RBD_IMAGE --size $SIZE"
fi
