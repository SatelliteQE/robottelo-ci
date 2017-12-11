#!/usr/bin/env bash
# Admin Credentials
ADMIN_USER="admin"

ADMIN_PASSWORD="changeme"

# Below are the default ID's of various Satellite6 entities.
# Basic Variables.
# ORG of ID 1 refers to 'Default Organization'
ORG=1 
# LOC of ID 2 refers to 'Default Location'
LOC=2

# The ID of the Default/Internal capsule, which is Satellite6 itself.
CAPSULE_ID=1

# Use this directly for ENV_VAR population and non side-effects on Satellite6 setup.
function satellite () {
    hammer -u ${ADMIN_USER} -p ${ADMIN_PASSWORD} "$@"
    if [ $? -ne 0 ]; then exit 1 ; fi
}

# Use this for all side-effects on a Satellite6 setup.
function satellite_runner () {
    [ ! -f /root/task_list.txt ] && touch /root/task_list.txt
    VAL=`echo "$@"`
    grep -Fxq "${VAL}" /root/task_list.txt > /dev/null
    RESULT=`echo $?`
    if [ "${RESULT}" -ne 0 ]; then
        satellite "$@"
        echo "$@" >> /root/task_list.txt
    fi
}

# Fix added for, https://github.com/redhat-performance/satellite-performance/issues/59
# Create the needed HostGroup and ActivationKeys

satellite_runner hostgroup create --name="HostGroup" --content-view="SatPerfContentView" --lifecycle-environment=Library --content-source-id=${CAPSULE_ID}  --puppet-proxy=$(hostname) --puppet-ca-proxy=$(hostname) --query-organization-id=${ORG} --location-ids=${LOC}

satellite_runner activation-key create --name="ActivationKey" --content-view="SatPerfContentView" --lifecycle-environment=Library --organization-id=${ORG}

RHEL_SUBS_ID=$(satellite --csv subscription list --organization-id=${ORG} | grep "RHEL7 x86_64 Base" |  awk -F "," '{print $1}' | grep -vi id)
SAT6_TOOLS_SUBS_ID=$(satellite --csv subscription list --organization-id=${ORG} | grep "Sat6 Tools" | awk -F "," '{print $1}' | grep -vi id )

satellite_runner activation-key add-subscription --name="ActivationKey" --organization-id=${ORG} --subscription-id=${RHEL_SUBS_ID}

satellite_runner activation-key add-subscription --name="ActivationKey" --organization-id=${ORG} --subscription-id=${SAT6_TOOLS_SUBS_ID}


# Fix for https://github.com/redhat-performance/satellite-performance/issues/61
satellite_runner settings set --name remote_execution_connect_by_ip --value true 
