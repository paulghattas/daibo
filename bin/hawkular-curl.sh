#!/bin/bash

TENANT=$1
EXTRA_ARGS=${@: 2}
TOKEN=`oc whoami -t`

curl -k -H "Authorization: Bearer $TOKEN" -H "Hawkular-Tenant: $TENANT" -X GET "$EXTRA_ARGS" | python -m json.tool

