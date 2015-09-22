pip install -U -r requirements.txt

# Set OS version for further use
if [ "${OS}" = 'rhel_7' ]; then
        export OS_VERSION='7'
elif [ "${OS}" = 'rhel_6' ]; then
        export OS_VERSION='6'
fi

# Source the Variables from files
source "${OPENSTACK_CONFIG}"
source "${SATELLITE6_REPOS_URLS}"
source "${SUBSCRIPTION_CONFIG}"

# Export required Environment variables
export BASE_URL="${SATELLITE6_OS_REPO}"
export CAPSULE_URL="${CAPSULE_OS_REPO}"
export TOOLS_URL="${TOOLS_OS_REPO}"

fab -i ~/.ssh/id_hudson_dsa -u root product_upgrade:"${PRODUCT}","${INSTANCE_NAME}","${IMAGE_NAME}","${IMAGE_FLAVOR}","${SSH_KEY_NAME}"
