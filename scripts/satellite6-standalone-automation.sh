set -o nounset

if [ -f "requirements-freeze.txt" ]; then
    pip install -U -r requirements-freeze.txt
else
    pip install -U -r requirements.txt docker-py pytest-xdist
fi

if [ -n "${ROBOTTELO_PROPERTIES:-}" ]; then
    echo "${ROBOTTELO_PROPERTIES}" > ./robottelo.properties
else
    source ${CONFIG_FILES}
    cp config/robottelo.properties ./robottelo.properties

    sed -i "s/{server_hostname}/${SERVER_HOSTNAME}/" robottelo.properties
    sed -i "s/^ssh_username.*/ssh_username=${SSH_USER}/" robottelo.properties

    sed -i "s/^admin_username.*/admin_username=${FOREMAN_ADMIN_USER}/" robottelo.properties
    sed -i "s/^admin_password.*/admin_password=${FOREMAN_ADMIN_PASSWORD}/" robottelo.properties
fi

pytest() {
    $(which py.test) -v --junit-xml=foreman-results.xml -m "${PYTEST_MARKS}" "$@"
}

if [ -n "${PYTEST_OPTIONS:-}" ]; then
    pytest ${PYTEST_OPTIONS}
    exit 0
fi

case "${TEST_TYPE}" in
    api|cli|ui|rhai|tier1|tier2|tier3 )
        make "test-foreman-${TEST_TYPE}" PYTEST_XDIST_NUMPROCESSES="${ROBOTTELO_WORKERS}"
        ;;
    endtoend-api|endtoend-cli|endtoend-ui )
        TEST_TYPE="$(echo ${TEST_TYPE} | cut -d- -f2)"
        pytest "tests/foreman/endtoend/test_${TEST_TYPE}_endtoend.py"
        ;;
    all )
        pytest tests/foreman/api tests/foreman/cli tests/foreman/ui
        ;;
    endtoend-all )
        make test-foreman-endtoend
        ;;
    * )
        echo "TEST_TYPE=\"${TEST_TYPE}\" not found."
        exit 1
        ;;
esac

# Remove any previous instances of foreman-debug tar file
rm -rf foreman-debug.tar.xz
# Disable error checking, for more information check the related issue
# http://projects.theforeman.org/issues/13442
# Let's continue to use this till we stop testing Satellite6.1 completely.
set +e
ssh "root@${SERVER_HOSTNAME}" foreman-debug -g -q -d "~/foreman-debug"
set -e
scp -r "root@${SERVER_HOSTNAME}:~/foreman-debug.tar.xz" .
