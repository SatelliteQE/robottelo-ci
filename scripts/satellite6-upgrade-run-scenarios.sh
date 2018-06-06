pip install -U -r requirements.txt docker-py pytest-xdist sauceclient

# Sourcing and exporting required env vars
source "${CONFIG_FILES}"
source config/compute_resources.conf
source config/sat6_upgrade.conf
source config/sat6_repos_urls.conf
source config/subscription_config.conf
source config/fake_manifest.conf
source config/installation_environment.conf


set +e
# Run pre-upgarde scenarios tests
if [ ${ENDPOINT} == 'pre-upgrade' ]; then
    $(which py.test)  -v --continue-on-collection-errors -s -m pre_upgrade --junit-xml=test_scenarios-pre-results.xml upgrade_tests/test_scenarios/
    # Creates the pre-upgrade data-store required for existence tests
    echo "Setting up pre-upgrade data-store for existence tests"
    fab -u root set_datastore:"preupgrade","cli"
    fab -u root set_datastore:"preupgrade","api"
else
    $(which py.test) -v --continue-on-collection-errors -s -m post_upgrade --junit-xml=test_scenarios-post-results.xml upgrade_tests/test_scenarios/
    # Delete the Original Manifest from the box to run robottelo tests
    fab -u root delete_manifest:"Default Organization"
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
