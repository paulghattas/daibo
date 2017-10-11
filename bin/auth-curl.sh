#!/bin/bash

curl -k -H "Authorization: Bearer `oc whoami -t`" "$@"
