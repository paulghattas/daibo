#!/bin/sh

oc adm policy add-cluster-role-to-user cluster-admin $@
