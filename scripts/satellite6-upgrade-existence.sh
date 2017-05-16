# Setting Prerequisites
pip install -r requirements.txt
set +e
$(which py.test) -v --continue-on-collection-errors --junit-xml=test_existance-results.xml upgrade_tests/test_existance_relations/
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
