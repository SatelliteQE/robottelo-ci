set -o nounset

pip install -U -r requirements.txt nose PyVirtualDisplay

cp "${ROBOTTELO_CONFIG}" ./robottelo.properties

sed -i "s/{server_hostname}/${SERVER_HOSTNAME}/" robottelo.properties
sed -i "s/^ssh_username.*/ssh_username=${SSH_USER}/" robottelo.properties

sed -i "s/^admin_username.*/admin_username=${FOREMAN_ADMIN_USER}/" robottelo.properties
sed -i "s/^admin_password.*/admin_password=${FOREMAN_ADMIN_PASSWORD}/" robottelo.properties

NOSETESTS="$(which nosetests) -s --logging-filter=nailgun,robottelo --with-xunit \
    --xunit-file=foreman-results.xml"

if [ -n "${NOSE_OPTIONS:-}" ]; then
    ${NOSETESTS} ${NOSE_OPTIONS}
    exit 0
fi

case "${TEST_TYPE}" in
    api|cli|ui|rhai )
        make "test-foreman-${TEST_TYPE}"
        ;;
    smoke-api|smoke-cli|smoke-ui )
        TEST_TYPE="$(echo ${TEST_TYPE} | cut -d- -f2)"
        ${NOSETESTS} "tests/foreman/smoke/test_${TEST_TYPE}_smoke.py"
        ;;
    all )
        ${NOSETESTS} "tests/foreman/api tests/foreman/cli tests/foreman/ui"
        ;;
    smoke-all )
        make test-foreman-smoke
        ;;
    * )
        echo "TEST_TYPE=\"${TEST_TYPE}\" not found."
        exit 1
        ;;
esac
