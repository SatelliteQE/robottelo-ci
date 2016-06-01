pip install -U -r requirements.txt

# Set OS version for further use
if [ "${OS}" = 'rhel7' ]; then
        export OS_VERSION='7'
elif [ "${OS}" = 'rhel6' ]; then
        export OS_VERSION='6'
fi

# Source the Variables from files
source "${RHEV_CONFIG}"
source "${SATELLITE6_REPOS_URLS}"
source "${SUBSCRIPTION_CONFIG}"

# Function to export RHEV environment variables based on selected OS
function export_rhev_env_var {
    if [ "${OS}" = 'rhel6' ]; then
        export SAT_IMAGE="${SAT_RHEL6_IMAGE}"
        export SAT_HOST="${SAT_RHEL6_HOSTNAME}"
        export CAP_IMAGE="${CAP_RHEL6_IMAGE}"
        export CAP_HOST="${CAP_RHEL6_HOSTNAME}"
    elif [ "${OS}" = 'rhel7' ]; then
        export SAT_IMAGE="${SAT_RHEL7_IMAGE}"
        export SAT_HOST="${SAT_RHEL7_HOSTNAME}"
        export CAP_IMAGE="${CAP_RHEL7_IMAGE}"
        export CAP_HOST="${CAP_RHEL7_HOSTNAME}"
    fi
}

if [ -n "${SATELLITE_HOSTNAME}" ]; then
    if [ "${DISTRIBUTION}" = 'CDN' ]; then
        # Run upgrade without compose urls
        fab -u root product_upgrade:"${UPGRADE_PRODUCT}"
    elif [ "${DISTRIBUTION}" = 'DOWNSTREAM' ]; then
        # Export required Environment variables
        export BASE_URL="${SATELLITE6_REPO}"
        export CAPSULE_URL="${CAPSULE_REPO}"
        # Run upgrade with above compose urls
        fab -u root product_upgrade:"${UPGRADE_PRODUCT}"
    fi
elif [ -n "${SATELLITE_IMAGE}" ]; then
    if [ "${DISTRIBUTION}" = 'CDN' ]; then
        # Run upgrade without compose urls
        fab -u root product_upgrade:"${UPGRADE_PRODUCT}","${SATELLITE_IMAGE}","${CAPSULE_IMAGE}"
    elif [ "${DISTRIBUTION}" = 'DOWNSTREAM' ]; then
        # Export required Environment variables
        export BASE_URL="${SATELLITE6_REPO}"
        export CAPSULE_URL="${CAPSULE_REPO}"
        # Run upgrade with above compose urls
        fab -u root product_upgrade:"${UPGRADE_PRODUCT}","${SATELLITE_IMAGE}","${CAPSULE_IMAGE}"
    fi
elif [ -z "${SATELLITE_IMAGE}" ] && [ -z "${CAPSULE_IMAGE}" ]; then
    if [ "${DISTRIBUTION}" = 'CDN' ]; then
        # Call function to export rhev image/hostname environment variables
        export_rhev_env_var
        # Run upgrade with exported rhev variables
        fab -u root product_upgrade:"${UPGRADE_PRODUCT}"
    elif [ "${DISTRIBUTION}" = 'DOWNSTREAM' ]; then
        # Call function to export rhev image/hostname environment variables
        export_rhev_env_var
        # Export required Environment variables
        export BASE_URL="${SATELLITE6_REPO}"
        export CAPSULE_URL="${CAPSULE_REPO}"
        # Run upgrade with above variables
        fab -u root product_upgrade:"${UPGRADE_PRODUCT}"
    fi
fi
