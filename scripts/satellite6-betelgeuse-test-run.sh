TEST_TEMPLATE_ID="Empty"

for path in tier{1,2,3,4}-{parallel,sequential}-results.xml; do
    case "$path" in
        tier1*)
            tier="Tier 1"
            ;;
        tier2*)
            tier="Tier 2"
            ;;
        tier3*)
            tier="Tier 3"
            ;;
        tier4*)
            tier="Tier 4"
            ;;
    esac

    betelgeuse -j auto test-run \
        --path "${path}" \
        --test-run-id "${TEST_RUN_ID} - ${tier}" \
        --test-template-id "${TEST_TEMPLATE_ID}" \
        --user ${POLARION_USER} \
        ${POLARION_DEFAULT_PROJECT}
done
