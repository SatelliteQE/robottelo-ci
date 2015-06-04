set -o nounset

pip install -U -r requirements.txt nose PyVirtualDisplay

# API automation will run all data-driven tests
if [ "${TEST_TYPE}" = 'api' ]; then
    SMOKE=0
else
    SMOKE=1
fi

cp "${ROBOTTELO_CONFIG}" ./robottelo.properties

sed -i "s/server\.hostname.*/server\.hostname=${SERVER_HOSTNAME}/" robottelo.properties
sed -i "s/server.ssh.username.*/server.ssh.username=${SSH_USER}/" robottelo.properties
sed -i "s/smoke.*/smoke=${SMOKE}/" robottelo.properties
sed -i "s/verbosity.*/verbosity=5/" robottelo.properties

sed -i "s/admin.username.*/admin.username=${FOREMAN_ADMIN_USER}/" robottelo.properties
sed -i "s/admin.password.*/admin.password=${FOREMAN_ADMIN_PASSWORD}/" robottelo.properties

NOSETESTS="$(which nosetests) --logging-filter=nailgun,robottelo --with-xunit \
    --xunit-file=foreman-results.xml"

if [ -n "${NOSE_OPTIONS}" ]; then
    ${NOSETESTS} ${NOSE_OPTIONS}
    exit 0
fi

case "${TEST_TYPE}" in
    api|cli|ui )
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
