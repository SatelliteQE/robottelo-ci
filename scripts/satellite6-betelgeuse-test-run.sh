TEST_TEMPLATE_ID="Empty"

# Create a new iteration for the current run
if [ ! -z "$RELEASE" ]; then
    betelgeuse test-plan --name "${TEST_RUN_ID}" --parent-name "${RELEASE}" \
        --plan-type iteration "${POLARION_DEFAULT_PROJECT}"
else
    betelgeuse test-plan --name "${TEST_RUN_ID}" \
        --plan-type iteration "${POLARION_DEFAULT_PROJECT}"
fi

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

    betelgeuse --token-prefix "@" test-run \
        --path "${path}" \
        --test-run-id "${TEST_RUN_ID} - ${tier}" \
        --test-template-id "${TEST_TEMPLATE_ID}" \
        --user "${POLARION_USER}" \
        --source-code-path tests/foreman \
        --custom-fields isautomated=True \
        --custom-fields arch=x8664 \
        --custom-fields variant=server \
        --custom-fields plannedin="${TEST_RUN_ID}" \
        "${POLARION_DEFAULT_PROJECT}"
done

# Mark the iteration done
betelgeuse test-plan \
    --name "${TEST_RUN_ID}" \
    --custom-fields status=done \
    "${POLARION_DEFAULT_PROJECT}"
