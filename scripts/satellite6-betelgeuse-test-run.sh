# Populate token-prefix and betelgeuse depending upon Satellite6 Version.
if [[ "${SATELLITE_VERSION}" = "6.1" ]] || [[ "${SATELLITE_VERSION}" = "6.2" ]] ; then
    pip install "betelgeuse<0.8"
    TOKEN_PREFIX="--token-prefix=@"
else
    pip install betelgeuse
    TOKEN_PREFIX=""
fi

# Create a new release with POLARION_RELEASE as the parent-plan.

if [ -n "$POLARION_RELEASE" ]; then
    betelgeuse test-plan --name "${POLARION_RELEASE}" --plan-type release \
    "${POLARION_PROJECT}"
else
    echo "Please specify the POLARION_RELEASE"
    exit 1
fi

# Change Test plan name for upgrade
if [[ "${TEST_RUN_ID}" = *"upgrade"* ]]; then
    TEST_PLAN_NAME = "${TEST_RUN_ID} upgrade"
else
    TEST_PLAN_NAME = "${TEST_RUN_ID}"
fi

# Create a new iteration for the current run
if [ -n "$POLARION_RELEASE" ]; then
    betelgeuse test-plan --name "${TEST_PLAN_NAME}" --parent-name "${POLARION_RELEASE}" \
        --plan-type iteration "${POLARION_PROJECT}"
else
    betelgeuse test-plan --name "${TEST_PLAN_NAME}" \
        --plan-type iteration "${POLARION_PROJECT}"
fi

POLARION_SELECTOR="name=Satellite 6"
SANITIZED_ITERATION_ID="$(echo ${TEST_RUN_ID} | sed 's|\.|_|g' | sed 's| |_|g')"

# Prepare the XML files
for tier in $(seq 1 4); do
   for run in parallel sequential; do
        betelgeuse ${TOKEN_PREFIX} xml-test-run \
            --custom-fields "isautomated=true" \
            --custom-fields "arch=x8664" \
            --custom-fields "variant=server" \
            --custom-fields "plannedin=${SANITIZED_ITERATION_ID}" \
            --response-property "${POLARION_SELECTOR}" \
            --test-run-id "${TEST_RUN_ID} - ${run} - Tier ${tier}" \
            "./tier${tier}-${run}-results.xml" \
            tests/foreman \
            "${POLARION_USERNAME}" \
            "${POLARION_PROJECT}" \
            "polarion-tier${tier}-${run}-results.xml"
        curl -k -u "${POLARION_USERNAME}:${POLARION_PASSWORD}" \
            -X POST \
            -F file=@polarion-tier${tier}-${run}-results.xml \
            "${POLARION_URL}import/xunit"
   done
done

# Mark the iteration done
betelgeuse test-plan \
    --name "${TEST_RUN_ID}" \
    --custom-fields status=done \
    "${POLARION_PROJECT}"
