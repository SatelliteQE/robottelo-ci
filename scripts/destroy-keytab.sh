#!/bin/bash -xe
#  destroy-keytab.sh - Script to remove kerberos credintials at the end of a
#    Jenkins job
#
# This script requires the following environment variables to be defined:
KRB5CCNAME="${KRB5CCNAME:?Most inject ouput file of load-keytab.sh}"

/usr/bin/kdestroy
: "Destroyed tickets at: $KRB5CCNAME"

