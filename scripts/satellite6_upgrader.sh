pip install -U -r requirements.txt

# Set OS version for further use
if [ "${OS}" = 'rhel7' ]; then
    export OS_VERSION='7'
elif [ "${OS}" = 'rhel6' ]; then
    export OS_VERSION='6'
fi

source ${CONFIG_FILES}
# Source the Variables from files
if [ -z "${SATELLITE_HOSTNAME}" ]; then
    source config/rhev.conf
fi
source config/sat6_repos_urls.conf
source config/subscription_config.conf

# Set Capsule URL as per OS
if [ "${OS}" = 'rhel7' ]; then
    CAPSULE_URL="${CAPSULE_RHEL7}"
elif [ "${OS}" = 'rhel6' ]; then
    CAPSULE_URL="${CAPSULE_RHEL6}"
fi

# Export required Environment variables for Downstream job
# As code in Automation Tools understands its Downstream :)
if [ "${DISTRIBUTION}" = 'DOWNSTREAM' ]; then
    export BASE_URL="${SATELLITE6_REPO}"
    export CAPSULE_URL
    export TOOLS_URL_RHEL6="${TOOLS_RHEL6}"
    export TOOLS_URL_RHEL7="${TOOLS_RHEL7}"
fi

# Run upgrade for CDN/Downstream
fab -u root product_upgrade:"${UPGRADE_PRODUCT}"
