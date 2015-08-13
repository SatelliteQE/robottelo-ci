pip install -U -r requirements.txt

# Figure out what version of RHEL the server uses
export OS_VERSION=$(fab -i ~/.ssh/id_hudson_dsa -H root@${SERVER_HOSTNAME} distro_info | grep "rhel [[:digit:]]" | cut -d ' ' -f 2)

source ${PROXY_CONFIG}
# OS_VERSION needs to be defined before sourcing SATELLITE6_REPOS_URLS
source ${SATELLITE6_REPOS_URLS}
source ${SUBSCRIPTION_CONFIG}
if [ "$STAGE_TEST" = 'false' ]; then
    source ${SUBSCRIPTION_CONFIG}
else
    source ${STAGE_CONFIG}
fi

if [ ${FIX_HOSTNAME} = "true" ]; then
    fab -i ~/.ssh/id_hudson_dsa -H root@${SERVER_HOSTNAME} fix_hostname
fi

if [ ${PARTITION_DISK} = "true" ]; then
    fab -i ~/.ssh/id_hudson_dsa -H root@${SERVER_HOSTNAME} partition_disk
fi


# ISOs require a specific URL
if [ ${DISTRIBUTION} = "ISO" ]; then
    export ISO_URL="${SATELLITE6_ISO_REPO}"
fi

# This is only used for downstream builds
if [ ${DISTRIBUTION} = "DOWNSTREAM" ]; then
    export BASE_URL="${SATELLITE6_OS_REPO}"
fi

fab -i ~/.ssh/id_hudson_dsa -H root@${SERVER_HOSTNAME} product_install:satellite6-${DISTRIBUTION},sat_cdn_version=${SATELLITE_VERSION},test_in_stage=${STAGE_TEST}

if [ ${SETUP_FAKE_MANIFEST_CERTIFICATE} = "true" ]; then
    source $FAKE_CERT_CONFIG
    fab -i ~/.ssh/id_hudson_dsa -H root@${SERVER_HOSTNAME} setup_fake_manifest_certificate
fi
