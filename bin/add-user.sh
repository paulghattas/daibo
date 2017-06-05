#!/bin/bash

cd /etc/origin/master
htpasswd -b ./htpasswd $@

