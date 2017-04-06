pip install -U -r requirements.txt

# Set OS version for further use
export OS_VERSION="${OS#rhel}"

source ${CONFIG_FILES}
# Source the Variables from files
if [ -z "${SATELLITE_HOSTNAME}" ]; then
    source config/compute_resources.conf
    source config/sat6_upgrade.conf
fi
export SATELLITE_VERSION="${TO_VERSION}"
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


# Sets up the satellite, capsule and clients on rhevm or personal boxes before upgrading
fab -u root setup_products_for_upgrade:"${UPGRADE_PRODUCT}","${OS}"

# Run upgrade for CDN/Downstream
if [ -z "${SATELLITE_HOSTNAME}" ]; then
    # If satellite_hostname is not provided, the upgrade will run on rhevm instances with the help of images
    fab -u root product_upgrade:"${UPGRADE_PRODUCT}","${RHEV_SAT_HOST}","${RHEV_CAP_HOST}"
else
    # Else user provided Satellite, Capsule and client will be upgraded
    fab -u root product_upgrade:"${UPGRADE_PRODUCT}","${SATELLITE_HOSTNAME}","${CAPSULE_HOSTNAMES}","${CLIENT6_HOSTS}","${CLIENT7_HOSTS}"
fi

# Run existance tests
if [ "${RUN_EXISTANCE_TESTS}" == 'true' ]; then
    $(which py.test) -v --junit-xml=test_existance-results.xml upgrade_tests/test_existance_relations/
fi

# Post Upgrade archive logs from log analyzer tool
if [ -d upgrade-diff-logs ]; then
    tar -czf Log_Analyzer_Logs.tar.xz upgrade-diff-logs
fi
