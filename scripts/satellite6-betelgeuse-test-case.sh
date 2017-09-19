# Install the latest version of betelgeuse.
pip install betelgeuse

betelgeuse requirement \
    "${BETELGEUSE_TC_PATH}" \
    "${POLARION_PROJECT}"

export PYTHONPATH="${PWD}"

cat > betelgeuse_config.py <<EOF
DEFAULT_APPROVERS_VALUE = '${POLARION_USERNAME}:approved'
DEFAULT_STATUS_VALUE = 'approved'
DEFAULT_SUBTYPE2_VALUE = '-'
EOF

betelgeuse --config-module "betelgeuse_config" test-case \
    --response-property "${BETELGEUSE_RESPONSE_PROPERTY}" \
    --automation-script-format "https://github.com/SatelliteQE/${BETELGEUSE_AUTOMATION_PROJECT}/blob/master/{path}#L{line_number}" \
    "${BETELGEUSE_TC_PATH}" \
    "${POLARION_PROJECT}" \
    polarion-test-cases.xml

curl -k -u "${POLARION_USERNAME}:${POLARION_PASSWORD}" \
    -X POST \
    -F file=@polarion-test-cases.xml \
    "${POLARION_URL}import/testcase"
