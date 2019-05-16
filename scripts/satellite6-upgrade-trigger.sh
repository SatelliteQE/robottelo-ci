# Fix variables
export CLIENTS_COUNT=8
export RUN_EXISTANCE_TESTS=true

# Sourcing and exporting required env vars
source "${CONFIG_FILES}"
source config/compute_resources.conf
source config/sat6_upgrade.conf
source config/sat6_repos_urls.conf
source config/subscription_config.conf
source config/fake_manifest.conf
source config/installation_environment.conf

# Fetching correct BASE_URL and CAPSULE_URL
export BASE_URL="${SATELLITE6_REPO}"
export CAPSULE_URL="${CAPSULE_REPO}"
export TOOLS_URL_RHEL6="${TOOLS_RHEL6}"
export TOOLS_URL_RHEL7="${TOOLS_RHEL7}"
export TOOLS_URL_RHEL8="${TOOLS_RHEL8}"

# Write a properties file to allow passing variables to T1 tests job.
echo "SERVER_HOSTNAME=${RHEV_SAT_HOST}" > properties.txt
echo "RHEL6_TOOLS_REPO=${TOOLS_RHEL6}" >> properties.txt
echo "RHEL7_TOOLS_REPO=${TOOLS_RHEL7}" >> properties.txt
echo "RHEL8_TOOLS_REPO=${TOOLS_RHEL8}" >> properties.txt
echo "CAPSULE_REPO=${CAPSULE_REPO}" >> properties.txt
echo "SUBNET=${SUBNET}" >> properties.txt
echo "NETMASK=${NETMASK}" >> properties.txt
echo "GATEWAY=${GATEWAY}" >> properties.txt
echo "BRIDGE=${BRIDGE}" >> properties.txt
echo "DISCOVERY_ISO=${DISCOVERY_ISO}" >> properties.txt


# Fix nailgun version for preupgrade tests as satellite will be on older version
sed -i "s/nailgun.git.*/nailgun.git@${FROM_VERSION}.z#egg=nailgun/" requirements.txt
# Setting Prerequisites
pip install -r requirements.txt
if [ ${ENDPOINT} == 'setup' ]; then
    # Sets up the satellite, capsule and clients on rhevm or personal boxes before upgrading
    fab -u root setup_products_for_upgrade:'longrun',"${OS}"

elif [ ${ENDPOINT} == 'upgrade' ]; then
    # Creates the pre-upgrade data-store required for existence tests
    echo "Setting up pre-upgrade data-store for existence tests before upgrade"
    fab -u root set_datastore:"preupgrade","cli"
    fab -u root set_datastore:"preupgrade","api"
    fab -u root set_templatestore:"preupgrade"
    tar -cf preupgrade_templates.tar.xz preupgrade_templates

    # Longrun to run upgrade on Satellite, capsule and clients
    fab -u root product_upgrade:'longrun'

    # Creates the post-upgrade data-store required for existence tests
    echo "Setting up post-upgrade data-store for existence tests post upgrade"
    fab -u root set_datastore:"postupgrade","cli"
    fab -u root set_datastore:"postupgrade","api"
    fab -u root set_templatestore:"postupgrade"
    tar -cf postupgrade_templates.tar.xz postupgrade_templates
fi
