
function setupRequirement () {
    pip install -U -r requirements.txt docker-py pytest-xdist sauceclient
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
    sed -i "s/{server_hostname}/${RHEV_SAT_HOST}/" robottelo.properties
    # Robottelo logging configuration
    sed -i "s/'\(robottelo\).log'/'\1-${ENDPOINT}.log'/" logging.conf
    # Bugzilla Login Details
    sed -i "s/# bz_password=.*/bz_password=${BUGZILLA_PASSWORD}/" robottelo.properties
    sed -i "s/# bz_username=.*/bz_username=${BUGZILLA_USER}/" robottelo.properties
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@"${SERVER_HOSTNAME}" -C "wget -O /etc/candlepin/certs/upstream/fake_manifest.crt $FAKE_MANIFEST_CERT_URL;systemctl restart tomcat"
}


set +e
# Run pre-upgarde scenarios tests
if [ ${ENDPOINT} == 'pre-upgrade' ]; then
    # Installing nailgun according to FROM_VERSION
    sed -i "s/nailgun.git.*/nailgun.git@${FROM_VERSION}.z#egg=nailgun/" requirements.txt
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
