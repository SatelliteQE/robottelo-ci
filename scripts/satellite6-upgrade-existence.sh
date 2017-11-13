# Setting Prerequisites
pip install -r requirements.txt
set +e
export ENDPOINT='cli'
$(which py.test) -v --continue-on-collection-errors --junit-xml=test_existance_cli-results.xml upgrade_tests/test_existance_relations/cli/
export ENDPOINT='api'
$(which py.test) -v --continue-on-collection-errors --junit-xml=test_existance_api-results.xml upgrade_tests/test_existance_relations/api/
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
