# Populate token-prefix and betelgeuse depending upon Satellite6 Version.

pip install Betelgeuse==1.7.0
TOKEN_PREFIX=""

wget https://raw.githubusercontent.com/SatelliteQE/robottelo-ci/master/lib/python/satellite6-polarion-test-plan.py

# Create a new release with POLARION_RELEASE as the parent-plan.
if [ -n "$POLARION_RELEASE" ]; then
    python satellite6-polarion-test-plan.py --name "${POLARION_RELEASE}" \
        --plan-type release "${POLARION_PROJECT}"
else
    echo "Please specify the POLARION_RELEASE"
    exit 1
fi

# Create a new iteration for the current run
if [ -n "$POLARION_RELEASE" ]; then
    python satellite6-polarion-test-plan.py --name "${TEST_RUN_ID}" \
        --parent-name "${POLARION_RELEASE}" \
        --plan-type iteration "${POLARION_PROJECT}"
else
    python satellite6-polarion-test-plan.py --name "${TEST_RUN_ID}" \
        --plan-type iteration "${POLARION_PROJECT}"
fi

POLARION_SELECTOR="name=Satellite 6"
SANITIZED_ITERATION_ID="$(echo ${TEST_RUN_ID} | sed 's|\.|_|g' | sed 's| |_|g')"
TEST_RUN_GROUP_ID="$(echo ${TEST_RUN_ID} | cut -d' ' -f2)"

# Prepare the XML files

if [[ "${TEST_RUN_ID}" = *"upgrade"* ]]; then
    TEST_RUN_ID="${TEST_RUN_ID} - Upgrade"
    # All tiers result upload
    for run in parallel sequential; do
        betelgeuse ${TOKEN_PREFIX} test-run \
        --custom-fields "isautomated=true" \
        --custom-fields "arch=x8664" \
        --custom-fields "variant=server" \
        --custom-fields "plannedin=${SANITIZED_ITERATION_ID}" \
        --response-property "${POLARION_SELECTOR}" \
        --test-run-title "${TEST_RUN_ID}" \
        --test-run-id "${TEST_RUN_ID}" \
        --test-run-group-id "${TEST_RUN_GROUP_ID}" \
        --status inprogress \
        "./all-tiers-upgrade-${run}-results.xml" \
        tests/foreman \
        "${POLARION_USERNAME}" \
        "${POLARION_PROJECT}" \
        "polarion-all-tiers-upgrade-${run}-results.xml"
        curl -k -u "${POLARION_USERNAME}:${POLARION_PASSWORD}" \
        -X POST \
        -F file=@polarion-all-tiers-upgrade-${run}-results.xml \
        "${POLARION_URL}import/xunit"
    done
    # end-to-end tier results upload
    betelgeuse ${TOKEN_PREFIX} test-run \
    --custom-fields "isautomated=true" \
    --custom-fields "arch=x8664" \
    --custom-fields "variant=server" \
    --custom-fields "plannedin=${SANITIZED_ITERATION_ID}" \
    --response-property "${POLARION_SELECTOR}" \
    --test-run-title "${TEST_RUN_ID}" \
    --test-run-id "${TEST_RUN_ID}" \
    --test-run-group-id "${TEST_RUN_GROUP_ID}" \
    --status inprogress \
    "./smoke-tests-results.xml" \
    tests/foreman \
    "${POLARION_USERNAME}" \
    "${POLARION_PROJECT}" \
    "polarion-smoke-upgrade-results.xml"
    curl -k -u "${POLARION_USERNAME}:${POLARION_PASSWORD}" \
    -X POST \
    -F file=@polarion-smoke-upgrade-results.xml \
    "${POLARION_URL}import/xunit"
elif [ "${ENDPOINT}" = "rhai" ] || [ "${ENDPOINT}" = "destructive" ]; then
    betelgeuse ${TOKEN_PREFIX} test-run \
        --custom-fields "isautomated=true" \
        --custom-fields "arch=x8664" \
        --custom-fields "variant=server" \
        --custom-fields "plannedin=${SANITIZED_ITERATION_ID}" \
        --response-property "${POLARION_SELECTOR}" \
        --test-run-title "${TEST_RUN_ID}" \
        --test-run-id "${TEST_RUN_ID}" \
        --test-run-group-id "${TEST_RUN_GROUP_ID}" \
        --status inprogress \
        "./foreman-results.xml" \
        tests/foreman \
        "${POLARION_USERNAME}" \
        "${POLARION_PROJECT}" \
        "polarion-${ENDPOINT##tier}-foreman-results.xml"
    curl -k -u "${POLARION_USERNAME}:${POLARION_PASSWORD}" \
        -X POST \
        -F file=@polarion-${ENDPOINT##tier}-foreman-results.xml \
        "${POLARION_URL}import/xunit"
else
    for run in parallel sequential; do
        betelgeuse ${TOKEN_PREFIX} test-run \
            --custom-fields "isautomated=true" \
            --custom-fields "arch=x8664" \
            --custom-fields "variant=server" \
            --custom-fields "plannedin=${SANITIZED_ITERATION_ID}" \
            --response-property "${POLARION_SELECTOR}" \
            --test-run-title "${TEST_RUN_ID}" \
            --test-run-id "${TEST_RUN_ID}" \
            --test-run-group-id "${TEST_RUN_GROUP_ID}" \
            --status inprogress \
            "./tier${ENDPOINT##tier}-${run}-results.xml" \
            tests/foreman \
            "${POLARION_USERNAME}" \
            "${POLARION_PROJECT}" \
            "polarion-tier${ENDPOINT##tier}-${run}-results.xml"
        curl -k -u "${POLARION_USERNAME}:${POLARION_PASSWORD}" \
            -X POST \
            -F file=@polarion-tier${ENDPOINT##tier}-${run}-results.xml \
            "${POLARION_URL}import/xunit"
    done
fi

# Mark the iteration done
python satellite6-polarion-test-plan.py \
    --name "${TEST_RUN_ID}" \
    "${POLARION_PROJECT}"
