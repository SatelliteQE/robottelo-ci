#!/bin/bash -xe
# load-keytab.sh - Script for loading a keytab as part of a jenkins job
#
# This script requires the following environment variables to be defined:
WORKSPACE="${WORKSPACE:?Must run in Jenkins or define WORKSPACE}"
KEYTAB_FILE="${KEYTAB_FILE:?Must define KEYTAB_FILE}"
KRB_PRINCIPAL="${KRB_PRINCIPAL:?Must define KRB_PRINCIPAL}"

chmod 600 "$KEYTAB_FILE"
export KRB5CCNAME="$(mktemp "$WORKSPACE/.krbcc.XXXXXX")"
chmod 600 "$KRB5CCNAME"
REAL_KEYTAB="$(mktemp "$WORKSPACE/.keytab.XXXXXX")"
chmod 600 "$REAL_KEYTAB"
/usr/bin/base64 -d < "$KEYTAB_FILE" > "$REAL_KEYTAB"
rm -f "$KEYTAB_FILE"
: "Credential cache at: $KRB5CCNAME"
/usr/bin/kinit "$KRB_PRINCIPAL" -k -t "$REAL_KEYTAB"
rm -f "$REAL_KEYTAB"
: "Loaded kerberos credentials:"
klist
echo "KRB5CCNAME=$KRB5CCNAME" > "$WORKSPACE/.krb5ccname"

