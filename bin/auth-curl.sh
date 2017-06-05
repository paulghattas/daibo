#!/bin/sh

curl -k -H "Authorization: Bearer `oc whoami -t`" $@
