# Setting Prerequisites
pip install -r requirements.txt
pip install -r requirements-optional.txt

# Untar templates data
tar -xf preupgrade_templates.tar.xz
tar -xf postupgrade_templates.tar.xz

set +e
export ENDPOINT='cli'
$(which py.test) -v --continue-on-collection-errors --junit-xml=test_existance_cli-results.xml -o junit_suite_name=test_existance_cli upgrade_tests/test_existance_relations/cli/
export ENDPOINT='api'
$(which py.test) -v --continue-on-collection-errors --junit-xml=test_existance_api-results.xml -o junit_suite_name=test_existance_api upgrade_tests/test_existance_relations/api/
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
