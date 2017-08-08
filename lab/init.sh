#!/bin/bash

# Create & Configure Users
echo "== Creating and Configuring Users ====="
htpasswd -b /etc/origin/master/htpasswd jdob redhat
htpasswd -b /etc/origin/master/htpasswd admin redhat
oc adm policy add-cluster-role-to-user cluster-admin admin
echo ""

# Create Volumes
echo "== Initializing Volumes ====="
oc create -f ./pv-nfs/all-pv.yaml
echo ""

echo "Initialization Complete"