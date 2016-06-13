# Exporting OS variable first to select correct env vars from config files
# according to OS
export OS="{os}"

pip install -r requirements.txt
source "${{RHEV_CONFIG}}"
source "${{SATELLITE6_REPOS_URLS}}"
source "${{SUBSCRIPTION_CONFIG}}"

function export_rhev_env_var {{
    if [ "${{OS}}" = 'rhel6' ]; then
        export SAT_IMAGE="${{SAT_RHEL6_IMAGE}}"
        export SAT_HOST="${{SAT_RHEL6_HOSTNAME}}"
        export CAP_IMAGE="${{CAP_RHEL6_IMAGE}}"
        export CAP_HOST="${{CAP_RHEL6_HOSTNAME}}"
        export BASE_URL="${{SATELLITE6_RHEL6}}"
        export CAPSULE_URL="${{CAPSULE_RHEL6}}"
        export TOOLS_URL="${{TOOLS_RHEL6}}"
    elif [ "${{OS}}" = 'rhel7' ]; then
        export SAT_IMAGE="${{SAT_RHEL7_IMAGE}}"
        export SAT_HOST="${{SAT_RHEL7_HOSTNAME}}"
        export CAP_IMAGE="${{CAP_RHEL7_IMAGE}}"
        export CAP_HOST="${{CAP_RHEL7_HOSTNAME}}"
        export BASE_URL="${{SATELLITE6_RHEL7}}"
        export CAPSULE_URL="${{CAPSULE_RHEL7}}"
        export TOOLS_URL="${{TOOLS_RHEL7}}"
    fi
}}

export_rhev_env_var
fab -u root product_upgrade:'satellite'
