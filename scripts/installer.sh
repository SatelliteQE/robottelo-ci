pip install -U -r requirements.txt

source ${PROXY_CONFIG}
source ${SUBSCRIPTION_CONFIG}

if [ ${FIX_HOSTNAME} = "true" ]; then
    fab -i ~/.ssh/id_hudson_dsa -H root@${SERVER_HOSTNAME} fix_hostname
fi

if [ ${PARTITION_DISK} = "true" ]; then
    fab -i ~/.ssh/id_hudson_dsa -H root@${SERVER_HOSTNAME} partition_disk
fi

# Figure out what version of RHEL the server uses
OS_VERSION=$(fab -i ~/.ssh/id_hudson_dsa -H root@${SERVER_HOSTNAME} distro_info | grep "rhel [[:digit:]]" | cut -d ' ' -f 2)

# ISOs require a specific URL
if [ ${DISTRIBUTION} = "ISO" ]; then
    export ISO_URL="${REPO_BASE_URL}/Satellite/latest-stable-Satellite-6.1-RHEL-${OS_VERSION}/compose/Satellite/x86_64/iso/"
fi

# This is only used for downstream builds
if [ ${DISTRIBUTION} = "DOWNSTREAM" ]; then
    export BASE_URL="${REPO_BASE_URL}/Satellite/latest-stable-Satellite-6.1-RHEL-${OS_VERSION}/compose/Satellite/x86_64/os/"
fi

fab -i ~/.ssh/id_hudson_dsa -H root@${SERVER_HOSTNAME} product_install:satellite6-${DISTRIBUTION}
