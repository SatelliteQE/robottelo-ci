# Fix variables
export CLIENTS_COUNT=8
export RUN_EXISTANCE_TESTS=true

# Sourcing and exporting required env vars
source "${{CONFIG_FILES}}"
source config/compute_resources.conf
source config/sat6_upgrade.conf
source config/sat6_repos_urls.conf
source config/subscription_config.conf
source config/fake_manifest.conf

# Fetching correct BASE_URL and CAPSULE_URL
export BASE_URL="${{SATELLITE6_REPO}}"
export CAPSULE_URL="${{CAPSULE_REPO}}"

# Write a properties file to allow passing variables to T1 tests job.
echo "SERVER_HOSTNAME=${{RHEV_SAT_HOST}}" > properties.txt
echo "RHEL6_TOOLS_REPO=${{TOOLS_RHEL6}}" >> properties.txt
echo "RHEL7_TOOLS_REPO=${{TOOLS_RHEL7}}" >> properties.txt
echo "CAPSULE_REPO=${{CAPSULE_REPO}}" >> properties.txt
echo "SUBNET=${{SUBNET}}" >> properties.txt
echo "NETMASK=${{NETMASK}}" >> properties.txt
echo "GATEWAY=${{GATEWAY}}" >> properties.txt
echo "BRIDGE=${{BRIDGE}}" >> properties.txt
echo "DISCOVERY_ISO=${{DISCOVERY_ISO}}" >> properties.txt

# Setting Prerequisites
pip install -r requirements.txt

# Sets up the satellite, capsule and clients on rhevm or personal boxes before upgrading
fab -u root setup_products_for_upgrade:'longrun',"{os}"

# Longrun to run upgrade on Satellite, capsule and clients
fab -u root product_upgrade:'longrun'
