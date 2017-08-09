#!/bin/bash

oc login -u jdob -p redhat

echo "== Creating Project ====="
oc new-project python-web
oc new-app jdob/python-web
oc expose service python-web
echo ""

echo "== Wait for Start ====="
sleep 60
echo ""

echo "== Querying Application ====="
HOST=`oc get route | grep apps.doblabs | awk '{print $2}'`
curl -k http://$HOST
echo ""

