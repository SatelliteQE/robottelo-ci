TEST_TEMPLATE_ID="Empty"

betelgeuse -j auto test-run \
    --path tier1-results.xml \
    --test-run-id "${TEST_RUN_ID} - Tier 1" \
    --test-template-id "${TEST_TEMPLATE_ID}" \
    --user ${POLARION_USER} \
    ${POLARION_DEFAULT_PROJECT}

betelgeuse -j auto test-run \
    --path tier2-results.xml \
    --test-run-id "${TEST_RUN_ID} - Tier 2" \
    --test-template-id "${TEST_TEMPLATE_ID}" \
    --user ${POLARION_USER} \
    ${POLARION_DEFAULT_PROJECT}

betelgeuse -j auto test-run \
    --path tier3-results.xml \
    --test-run-id "${TEST_RUN_ID} - Tier 3" \
    --test-template-id "${TEST_TEMPLATE_ID}" \
    --user ${POLARION_USER} \
    ${POLARION_DEFAULT_PROJECT}

betelgeuse -j auto test-run \
    --path tier4-results.xml \
    --test-run-id "${TEST_RUN_ID} - Tier 4" \
    --test-template-id "${TEST_TEMPLATE_ID}" \
    --user ${POLARION_USER} \
    ${POLARION_DEFAULT_PROJECT}
