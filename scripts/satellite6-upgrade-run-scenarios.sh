
function setupRequirement () {
    pip install -U -r requirements.txt docker-py pytest-xdist==1.27.0 sauceclient
    pip install -r requirements-optional.txt
}

# Sourcing and exporting required env vars and setting up robottelo properties

function setupPrerequisites () {
    source "${CONFIG_FILES}"
    source config/compute_resources.conf
    source config/sat6_upgrade.conf
    source config/sat6_repos_urls.conf
    source config/subscription_config.conf
    source config/fake_manifest.conf
    source config/installation_environment.conf
    cp config/robottelo.properties ./robottelo.properties
    cp config/robottelo.yaml ./robottelo.yaml
    sed -i "s/{server_hostname}/${RHEV_SAT_HOST}/" robottelo.properties
    sed -i "s/# rhev_cap_host=.*/rhev_cap_host=${RHEV_CAP_HOST}/" robottelo.properties
    sed -i "s/# rhev_capsule_ak=.*/rhev_capsule_ak=${RHEV_CAPSULE_AK}/" robottelo.properties
    sed -i "s/# from_version=.*/from_version=${FROM_VERSION}/" robottelo.properties
    sed -i "s/# to_version=.*/to_version=${TO_VERSION}/" robottelo.properties
    sed -i "s/^# \[vlan_networking\].*/[vlan_networking]/" robottelo.properties
    sed -i "s/# bridge=.*/bridge=${BRIDGE}/" robottelo.properties
    sed -i "s/# subnet=.*/subnet=${SUBNET}/" robottelo.properties
    sed -i "s/# gateway=.*/gateway=${GATEWAY}/" robottelo.properties
    sed -i "s/# netmask=.*/netmask=${NETMASK}/" robottelo.properties

    sed -i "s|sattools_repo=.*|sattools_repo=rhel8=${RHEL8_TOOLS_REPO},rhel7=${RHEL7_TOOLS_REPO},rhel6=${RHEL6_TOOLS_REPO}|" robottelo.properties
    # Robottelo logging configuration
    sed -i "s/'\(robottelo\).log'/'\1-${ENDPOINT}.log'/" logging.conf
    # Bugzilla Login Details
    sed -i "/^\[bugzilla\]/,/^\[/s/^#\?api_key=\w*/api_key=${BUGZILLA_KEY}/" robottelo.properties
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@"${SERVER_HOSTNAME}" -C "wget -O /etc/candlepin/certs/upstream/fake_manifest.crt $FAKE_MANIFEST_CERT_URL;systemctl restart tomcat"
}

# Pre-Upgrade specific required updates to environment
function setupPreUpgrade () {
    # Installing nailgun according to FROM_VERSION
    sed -i "s/nailgun.git.*/nailgun.git@${FROM_VERSION}.z#egg=nailgun/" requirements.txt
    # Setting the SATELLITE_VERSION to FROM_VERSION for sourcing correct environment variables
    export SATELLITE_VERSION="${FROM_VERSION}"
}

set +e
# Run pre-upgarde scenarios tests
if [ ${ENDPOINT} == 'pre-upgrade' ]; then
    setupPreUpgrade
    setupRequirement
    setupPrerequisites
    $(which py.test)  -v --continue-on-collection-errors -s -m pre_upgrade --junit-xml=test_scenarios-pre-results.xml -o junit_suite_name=test_scenarios-pre tests/upgrades
else
    setupRequirement
    setupPrerequisites
    $(which py.test) -v --continue-on-collection-errors -s -m post_upgrade --junit-xml=test_scenarios-post-results.xml -o junit_suite_name=test_scenarios-post tests/upgrades
    # Delete the Original Manifest from the box to run robottelo tests
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@"${SERVER_HOSTNAME}" "hammer -u admin -p changeme subscription delete-manifest --organization 'Default Organization'"
fi
set -e

echo
echo "========================================"
echo "Server information"
echo "========================================"
echo "Hostname: $SERVER_HOSTNAME"
echo "Credentials: admin/changeme"
echo "========================================"
echo
echo "========================================"
