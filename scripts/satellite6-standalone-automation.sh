set -o nounset

if [ "${ROBOTTELO_BRANCH}" = "6.1.z" ]; then
    pip install -U -r requirements-freeze.txt
else
    pip install -U -r requirements.txt docker-py pytest-xdist
fi

cp "${ROBOTTELO_CONFIG}" ./robottelo.properties

sed -i "s/{server_hostname}/${SERVER_HOSTNAME}/" robottelo.properties
sed -i "s/^ssh_username.*/ssh_username=${SSH_USER}/" robottelo.properties

sed -i "s/^admin_username.*/admin_username=${FOREMAN_ADMIN_USER}/" robottelo.properties
sed -i "s/^admin_password.*/admin_password=${FOREMAN_ADMIN_PASSWORD}/" robottelo.properties

pytest() {
    $(which py.test) -v --junit-xml=foreman-results.xml -m "${PYTEST_MARKS}" "$@"
}

if [ -n "${PYTEST_OPTIONS:-}" ]; then
    pytest ${PYTEST_OPTIONS}
    exit 0
fi

case "${TEST_TYPE}" in
    api|cli|ui|rhai|tier1|tier2|tier3 )
        make "test-foreman-${TEST_TYPE}" PYTEST_XDIST_NUMPROCESSES=4
        ;;
    smoke-api|smoke-cli|smoke-ui )
        TEST_TYPE="$(echo ${TEST_TYPE} | cut -d- -f2)"
        pytest "tests/foreman/smoke/test_${TEST_TYPE}_smoke.py"
        ;;
    all )
        pytest tests/foreman/api tests/foreman/cli tests/foreman/ui
        ;;
    smoke-all )
        make test-foreman-smoke
        ;;
    * )
        echo "TEST_TYPE=\"${TEST_TYPE}\" not found."
        exit 1
        ;;
esac
