#!/bin/bash

TOKEN=`oc whoami -t`
curl -k -H "Authorization: Bearer $TOKEN" "$@"
