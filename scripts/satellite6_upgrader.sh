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
source config/installation_environment.conf

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

if [ "${PERFORM_FOREMAN_MAINTAIN_UPGRADE}" != "true" ]; then
    # Sets up the satellite, capsule and clients on rhevm or personal boxes before upgrading
    fab -u root setup_products_for_upgrade:"${UPGRADE_PRODUCT}","${OS}"
fi

set +e
# Run pre-upgarde scenarios tests
if [ "${RUN_SCENARIO_TESTS}" == 'true' ]; then
    $(which py.test) -v -s -m pre_upgrade --junit-xml=test_scenarios-pre-results.xml upgrade_tests/test_scenarios/
fi
set -e

# Creates the pre-upgrade data-store required for existence tests
if [ "${RUN_EXISTANCE_TESTS}" == 'true' ]; then
    echo "Setting up pre-upgrade data-store for existence tests"
    fab -u root set_datastore:"preupgrade","cli"
    fab -u root set_datastore:"preupgrade","api"
fi

# Get the Satellite hostname which will be used by job
if [ -z "${SATELLITE_HOSTNAME}" ]; then
    export SAT_HOST="${RHEV_SAT_HOST}"
fi

# Run pre-upgrade scripts to replicate custom scenarios
if [ -n "${CUSTOM_SCRIPT_URL}" ]; then
    echo "Running Pre-Upgrade Custom script"
    wget "${CUSTOM_SCRIPT_URL}"
    custom_file="${CUSTOM_SCRIPT_URL}"
    shopt -s extglob;
    export custom_file=${custom_file##+(*/)}
    chmod 755 ${custom_file}
    scp ${custom_file} root@"${SAT_HOST}":.
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@"${SAT_HOST}" chmod 755 /root/${custom_file}
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@"${SAT_HOST}" /root/${custom_file}
fi

# Run satellite upgrade only when PERFORM_FOREMAN_MAINTAIN_UPGRADE flag is set
if [ "${PERFORM_FOREMAN_MAINTAIN_UPGRADE}" == "true" ]; then
    # setup foreman-maintain
    fab -H root@"${SATELLITE_HOSTNAME}" setup_foreman_maintain
    # perform upgrade using foreman-maintain
    fab -H root@"${SATELLITE_HOSTNAME}" upgrade_using_foreman_maintain
else
    fab -u root product_upgrade:"${UPGRADE_PRODUCT}"
fi

# Creates the post-upgrade data-store required for existence tests
if [ "${RUN_EXISTANCE_TESTS}" == 'true' ]; then
    echo "Setting up post-upgrade data-store for existence tests"
    fab -u root set_datastore:"postupgrade","cli"
    fab -u root set_datastore:"postupgrade","api"
fi

set +e
# Run post-upgarde scenarios tests
if [ "${RUN_SCENARIO_TESTS}" == 'true' ]; then
    $(which py.test) -v -s -m post_upgrade --junit-xml=test_scenarios-post-results.xml upgrade_tests/test_scenarios/
fi
set -e

# Export BZ credentials to skip the tests with BZ
# This will be used robozilla's pytest_skip_if_bug_open decorator
export BUGZILLA_ENVIRON_USER_NAME="${BUGZILLA_USER}"
export BUGZILLA_ENVIRON_USER_PASSWORD_NAME="${BUGZILLA_PASSWORD}"
export BUGZILLA_ENVIRON_SAT_VERSION="${TO_VERSION}"

# Run existance tests
if [ "${RUN_EXISTANCE_TESTS}" == 'true' ]; then
    set +e
    export ENDPOINT='cli'
    $(which py.test) -v --continue-on-collection-errors --junit-xml=test_existance_cli-results.xml upgrade_tests/test_existance_relations/cli/

    export ENDPOINT='api'
    $(which py.test) -v --continue-on-collection-errors --junit-xml=test_existance_api-results.xml upgrade_tests/test_existance_relations/api/
    set -e
fi

# Post Upgrade archive logs from log analyzer tool
if [ -d upgrade-diff-logs ]; then
    tar -czf Log_Analyzer_Logs.tar.xz upgrade-diff-logs
fi
