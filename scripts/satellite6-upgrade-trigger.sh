# Setting Prerequisites
pip install -r requirements.txt

#Setting up required Variables
export OS="{os}"
export OS_VERSION="${{OS: -1}}"
export SATELLITE_VERSION="${{SATELLITE_VERSION:-$TO_VERSION}}"

# Sourcing and exporting required env vars
source "${{CONFIG_FILES}}"
source config/compute_resources.conf
source config/sat6_upgrade.conf
source config/sat6_repos_urls.conf
source config/subscription_config.conf

# Fetching correct BASE_URL and CAPSULE_URL
export BASE_URL="${{SATELLITE6_REPO}}"
export CAPSULE_URL="${{CAPSULE_REPO}}"

if [ "${{TO_VERSION}}" = '6.1' ]; then
    echo "ALERT!! The upgrade from 6.0 to 6.1 is not supported! Please perform it manually"
    exit 1
fi

# Run Capsule Upgrade to run both satellite and capsule upgrade
fab -u root product_upgrade:'capsule'
