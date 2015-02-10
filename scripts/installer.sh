pip install -U -r requirements.txt

if [ $BUILD_USER_ID = "omaciel" ]; then
    fab -i ~/.ssh/id_hudson_dsa -H root@$SERVER_HOSTNAME fix_hostname partition_disk
fi

# Figure out what version of RHEL the server uses
OS_VERSION=$(fab -i ~/.ssh/id_hudson_dsa -H root@$SERVER_HOSTNAME distro_info | grep "rhel \d" | cut -d ' ' -f 2)

# ISOs require a specific URL
if [ $DISTRIBUTION = "ISO" ]; then
    export ISO_URL="${REPO_BASE_URL}/Satellite/latest-stable-Satellite-6.0-RHEL-${OS_VERSION}/compose/Satellite/x86_64/iso/"
fi

# This is only used for downstream builds
if [ $DISTRIBUTION = "DOWNSTREAM" ]; then
    export BASE_URL="${REPO_BASE_URL}/Satellite/latest-stable-Satellite-6.0-RHEL-${OS_VERSION}/compose/Satellite/x86_64/os/"
fi

fab -i ~/.ssh/id_hudson_dsa -H root@$SERVER_HOSTNAME product_install:satellite6-${DISTRIBUTION}
