pip install -U -r requirements.txt

# Figure out what version of RHEL the server uses
export OS_VERSION=$(fab -H root@${SERVER_HOSTNAME} distro_info | grep "rhel [[:digit:]]" | cut -d ' ' -f 2)
DISTRO="rhel${OS_VERSION}"

source ${CONFIG_FILES}
source config/installation_environment.conf
source config/proxy_config_environment.conf
# OS_VERSION needs to be defined before sourcing sat6_repos_urls.conf
source config/sat6_repos_urls.conf
# DISTRO needs to be defined before sourcing subscription_config.conf
source config/subscription_config.conf
if [ "$STAGE_TEST" = 'true' ]; then
    source config/stage_environment.conf
fi
if [ "${PUPPET4}" = 'true' ]; then
    export PUPPET4_REPO # sourced from installation_environment.conf
fi

if [ ${FIX_HOSTNAME} = "true" ]; then
    fab -H root@${SERVER_HOSTNAME} fix_hostname
fi

if [ ${PARTITION_DISK} = "true" ]; then
    fab -H root@${SERVER_HOSTNAME} partition_disk
fi

# Assign DISTRIBUTION to trigger things appropriately from automation-tools.
if [ "${SATELLITE_DISTRIBUTION}" = "INTERNAL" ]; then
    export DISTRIBUTION="satellite6-downstream"
elif [ "${SATELLITE_DISTRIBUTION}" = "GA" ]; then
    export DISTRIBUTION="satellite6-cdn"
elif [ "${SATELLITE_DISTRIBUTION}" = "BETA" ]; then
    export DISTRIBUTION="satellite6-beta"
elif [ "${SATELLITE_DISTRIBUTION}" = "UPSTREAM" ]; then
    export DISTRIBUTION="satellite6-upstream"
elif [ "${SATELLITE_DISTRIBUTION}" = "INTERNAL REPOFILE" ]; then
    export DISTRIBUTION="satellite6-repofile"
elif [ "${SATELLITE_DISTRIBUTION}" = "INTERNAL AK" ]; then
    export DISTRIBUTION="satellite6-activationkey"
elif [ "${SATELLITE_DISTRIBUTION}" = "ISO" ]; then
    export DISTRIBUTION="satellite6-iso"
fi

# ISOs require a specific URL
if [ "${SATELLITE_DISTRIBUTION}" = "ISO" ]; then
    # If user provided custom baseurl, use it otherwise use the default
    if [ ! -z "$SATELLITE6_CUSTOM_BASEURL" ]; then
        export ISO_URL="${SATELLITE6_CUSTOM_BASEURL}"
    else
        export ISO_URL="${SATELLITE6_ISO_REPO}"
    fi
fi

# This is only used for downstream builds
if [ "${SATELLITE_DISTRIBUTION}" = "INTERNAL" ]; then
    # If user provided custom baseurl, use it otherwise use the default
    if [ ! -z "$SATELLITE6_CUSTOM_BASEURL" ]; then
        export BASE_URL="${SATELLITE6_CUSTOM_BASEURL}"
    else
        export BASE_URL="${SATELLITE6_REPO}"
    fi
fi

fab -H root@${SERVER_HOSTNAME} product_install:${DISTRIBUTION},sat_cdn_version=${SATELLITE_VERSION},test_in_stage=${STAGE_TEST}

if [ ${SETUP_FAKE_MANIFEST_CERTIFICATE} = "true" ]; then
    source config/fake_manifest.conf
    fab -H root@${SERVER_HOSTNAME} setup_fake_manifest_certificate
fi
