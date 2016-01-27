betelgeuse -j auto test-run \
    --path tier1-results.xml \
    --test-run-id "${TEST_RUN_ID} - Tier 1" \
    --user ${POLARION_USER} \
    ${POLARION_DEFAULT_PROJECT}

betelgeuse -j auto test-run \
    --path tier2-results.xml \
    --test-run-id "${TEST_RUN_ID} - Tier 2" \
    --user ${POLARION_USER} \
    ${POLARION_DEFAULT_PROJECT}

betelgeuse -j auto test-run \
    --path tier3-results.xml \
    --test-run-id "${TEST_RUN_ID} - Tier 3" \
    --user ${POLARION_USER} \
    ${POLARION_DEFAULT_PROJECT}
