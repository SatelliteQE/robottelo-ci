# Install the latest version of betelgeuse.
pip install Betelgeuse==0.15.0


if [[ ${BETELGEUSE_AUTOMATION_PROJECT} = "satellite6-upgrade" ]]; then
    export BETELGEUSE_TC_PATH='upgrade_tests/test_existance_relations'
elif [[ "${SATELLITE_VERSION}" = "6.4" ]] || [[ "${SATELLITE_VERSION}" = "6.5" ]]; then
    export BETELGEUSE_TC_PATH='tests/foreman/api tests/foreman/cli tests/foreman/ui_airgun tests/foreman/longrun tests/foreman/sys tests/foreman/installer tests/foreman/rhai'
else
    export BETELGEUSE_TC_PATH='tests/foreman/api tests/foreman/cli tests/foreman/ui tests/foreman/longrun tests/foreman/sys tests/foreman/installer tests/foreman/rhai'
fi

for TC_PATH in $(echo ${BETELGEUSE_TC_PATH}) ; do \
betelgeuse requirement \
    ${TC_PATH} \
    "${POLARION_PROJECT}" ; done

export PYTHONPATH="${PWD}"

cat > betelgeuse_config.py <<EOF
from betelgeuse import default_config
DEFAULT_APPROVERS_VALUE = '${POLARION_USERNAME}:approved'
DEFAULT_STATUS_VALUE = 'approved'
DEFAULT_SUBTYPE2_VALUE = '-'
TESTCASE_CUSTOM_FIELDS = default_config.TESTCASE_CUSTOM_FIELDS + ('customerscenario',)
TRANSFORM_CUSTOMERSCENARIO_VALUE = default_config._transform_to_lower
DEFAULT_CUSTOMERSCENARIO_VALUE = 'false'
EOF

for TC_PATH in $(echo ${BETELGEUSE_TC_PATH}) ; do \
betelgeuse --config-module "betelgeuse_config" test-case \
    --response-property "${BETELGEUSE_RESPONSE_PROPERTY}" \
    --automation-script-format "https://github.com/SatelliteQE/${BETELGEUSE_AUTOMATION_PROJECT}/blob/master/{path}#L{line_number}" \
    ${TC_PATH} \
    "${POLARION_PROJECT}" \
    polarion-test-cases.xml ; \
curl -k -u "${POLARION_USERNAME}:${POLARION_PASSWORD}" \
    -X POST \
    -F file=@polarion-test-cases.xml \
    "${POLARION_URL}import/testcase" ; done
