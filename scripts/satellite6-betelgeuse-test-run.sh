TEST_TEMPLATE_ID="Empty"

# Create a new iteration for the current run
if [ ! -z "$POLARION_RELEASE" ]; then
    betelgeuse test-plan --name "${TEST_RUN_ID}" --parent-name "${POLARION_RELEASE}" \
        --plan-type iteration "${POLARION_DEFAULT_PROJECT}"
else
    betelgeuse test-plan --name "${TEST_RUN_ID}" \
        --plan-type iteration "${POLARION_DEFAULT_PROJECT}"
fi

TEST_PLAN_ID="$(python - <<END
import re
import os
from betelgeuse import INVALID_CHARS_REGEX
plan_id = re.sub(INVALID_CHARS_REGEX, '_', os.environ['TEST_RUN_ID']).replace(' ', '_')
print plan_id
END
)"

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
        --custom-fields plannedin="${TEST_PLAN_ID}" \
        "${POLARION_DEFAULT_PROJECT}"
done

# Mark the iteration done
betelgeuse test-plan \
    --name "${TEST_RUN_ID}" \
    --custom-fields status=done \
    "${POLARION_DEFAULT_PROJECT}"
