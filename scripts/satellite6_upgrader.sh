# ==================================================== Define Functions for both in common processes =====================================

function setupRequirement () {
    # https://github.com/SatelliteQE/robottelo-ci/issues/1873
    pip install -U 'pip<21.0'
    pip install -U --use-deprecated=legacy-resolver -r requirements.txt
    pip install -r requirements-optional.txt
}

function setupPrerequisites () {
    export OS_VERSION="${OS#rhel}"

    # BZ exports for post-upgrade scenario tests
    export BUGZILLA_ENVIRON_USER_NAME="${BUGZILLA_USER}"
    export BUGZILLA_ENVIRON_USER_PASSWORD_NAME="${BUGZILLA_PASSWORD}"
    export BUGZILLA_ENVIRON_SAT_VERSION="${TO_VERSION}"

    source ${CONFIG_FILES}

    # Sourcing the required files first
    if [ -z "${SATELLITE_HOSTNAME}" ]; then
        source config/compute_resources.conf
        source config/sat6_upgrade.conf
    fi

    # Get the Satellite hostname which will be used by job
    if [ -z "${SATELLITE_HOSTNAME}" ]; then
        export SAT_HOST="${RHEV_SAT_HOST}"
    else
        export SAT_HOST="${SATELLITE_HOSTNAME}"
    fi

    # Source the Variables from files
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
        export TOOLS_URL_RHEL8="${TOOLS_RHEL8}"
    fi
}

# ==================================================== Define Functions for preupgrade process =====================================

# Pre-Upgrade specific required updates to environment
function setupPreUpgrade () {
    # Installing nailgun according to FROM_VERSION
    sed -i "s/nailgun.git.*/nailgun.git@${FROM_VERSION}.z#egg=nailgun/" requirements.txt

    # Setting the SATELLITE_VERSION to FROM_VERSION for sourcing correct environment variables
    export SATELLITE_VERSION="${FROM_VERSION}"
}

function beforeUpgrade () {
    setupPreUpgrade
    setupRequirement
    setupPrerequisites

    # Run pre-upgarde scenarios tests
    set +e
    if [ "${RUN_SCENARIO_TESTS}" == 'true' ]; then
        $(which py.test) -v -s -m pre_upgrade --junit-xml=test_scenarios-pre-results.xml -o junit_suite_name=test_scenarios-pre upgrade_tests/test_scenarios/
    fi
    set -e

    # Creates the pre-upgrade data-store required for existence tests
    if [ "${RUN_EXISTANCE_TESTS}" == 'true' ]; then
        echo "Setting up pre-upgrade data-store for existence tests"
        fab -u root set_datastore:"preupgrade","cli"
        fab -u root set_datastore:"preupgrade","api"
        fab -u root set_templatestore:"preupgrade"
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
}


# ==================================================== Define Functions for Upgrade process =====================================

# Pre-Upgrade specific required updates to environment
function setupUpgrade () {
    # Nailgun is already installed of previous version as expected, so nt required to reinstall
    ## sed -i "s/nailgun.git.*/nailgun.git@${FROM_VERSION}.z#egg=nailgun/" requirements.txt

    # Setting the SATELLITE_VERSION to FROM_VERSION for sourcing correct environment variables
    export SATELLITE_VERSION="${TO_VERSION}"
}

function Upgrade () {
    setupUpgrade
    # No changes in requirements, so not implemented
    setupPrerequisites

    # Sets up the satellite, capsule and clients on rhevm or personal boxes before upgrading
    fab -u root setup_products_for_upgrade:"${UPGRADE_PRODUCT}","${OS}"

    # Perform Upgrade
    if [ "${FOREMAN_MAINTAIN_SATELLITE_UPGRADE}" == "true" ]; then
        # setup foreman-maintain
        fab -H root@"${SAT_HOST}" setup_foreman_maintain
    fi

    # Run Upgrades on products given
    fab -u root product_upgrade:"${UPGRADE_PRODUCT}"
}



# ==================================================== Define Functions for postupgrade process =====================================

function setupPostUpgrade () {
    # The nailgun version will be installed as per TO_VERSION, hence not implemented
    # Setting the SATELLITE_VERSION to TO_VERSION for sourcing correct environment variables
    export SATELLITE_VERSION="${TO_VERSION}"
}

function afterUpgrade () {
    setupPostUpgrade
    setupRequirement
    setupPrerequisites
    # Creates Templates after upgrading the instances
    if [ "${CREATE_TEMPLATES}" == 'true' ]; then
        echo "Creating Upgraded Instances of Satellite and Capsule"
        fab -u root validate_and_create_rhevm4_templates:"${UPGRADE_PRODUCT}"
    fi

    # Creates the post-upgrade data-store required for existence tests
    if [ "${RUN_EXISTANCE_TESTS}" == 'true' ]; then
        echo "Setting up post-upgrade data-store for existence tests"
        fab -u root set_datastore:"postupgrade","cli"
        fab -u root set_datastore:"postupgrade","api"
        fab -u root set_templatestore:"postupgrade"
        set +e
        export ENDPOINT='cli'
        $(which py.test) -v --continue-on-collection-errors --junit-xml=test_existance_cli-results.xml -o junit_suite_name=test_existance_cli upgrade_tests/test_existance_relations/cli/
        export ENDPOINT='api'
        $(which py.test) -v --continue-on-collection-errors --junit-xml=test_existance_api-results.xml -o junit_suite_name=test_existance_api upgrade_tests/test_existance_relations/api/
        set -e
    fi

    set +e
    # Run post-upgarde scenarios tests
    if [ "${RUN_SCENARIO_TESTS}" == 'true' ]; then
        $(which py.test) -v -s -m post_upgrade --junit-xml=test_scenarios-post-results.xml -o junit_suite_name=test_scenarios-post upgrade_tests/test_scenarios/
    fi
    set -e

    # Post Upgrade archive logs from log analyzer tool
    if [ -d upgrade-diff-logs ]; then
        tar -czf Log_Analyzer_Logs.tar.xz upgrade-diff-logs
    fi
}

# ==================================================== The Start of Standalone =====================================

# Before upgrade process
beforeUpgrade

# Running Upgrade
Upgrade

# After upgrade process
afterUpgrade

# ==================================================== The End of Standalone =====================================
