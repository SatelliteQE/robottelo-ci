pip install -U -r requirements.txt

# Set OS version for further use
if [ "${OS}" = 'rhel7' ]; then
    export OS_VERSION='7'
elif [ "${OS}" = 'rhel6' ]; then
    export OS_VERSION='6'
fi

# Source the Variables from files
if [ -z "${SATELLITE_HOSTNAME}" ]; then
    source "${RHEV_CONFIG}"
fi
source "${SATELLITE6_REPOS_URLS}"
source "${SUBSCRIPTION_CONFIG}"

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
fi

# Run upgrade for CDN/Downstream
fab -u root product_upgrade:"${UPGRADE_PRODUCT}"
