# Setting Prerequisites
pip install -r requirements.txt

#Setting up required Variables for populating the Sat6 Repos needed by config/sat6_repos_urls.conf file.
export OS="{os}"
export SATELLITE_VERSION="{satellite_version}"
# Specify DISTRO as subscription_config file requires it.
export DISTRO="${{OS}}"
export OS_VERSION="${{OS: -1}}"
export TO_VERSION="${{SATELLITE_VERSION}}"
if [ "${{ZSTREAM_UPGRADE}}" = 'true' ]; then
    export FROM_VERSION="${{TO_VERSION}}"
else
    export FROM_VERSION=$(echo ${{SATELLITE_VERSION}} - 0.1 | bc)
fi
export CLIENTS_COUNT=8

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
echo "TOOLS_REPO=${{TOOLS_REPO}}" >> properties.txt
echo "SUBNET=${{SUBNET}}" >> properties.txt
echo "NETMASK=${{NETMASK}}" >> properties.txt
echo "GATEWAY=${{GATEWAY}}" >> properties.txt
echo "BRIDGE=${{BRIDGE}}" >> properties.txt
echo "DISCOVERY_ISO=${{DISCOVERY_ISO}}" >> properties.txt


if [ "${{TO_VERSION}}" = '6.1' ]; then
    echo "ALERT!! The upgrade from 6.0 to 6.1 is not supported! Please perform it manually"
    exit 1
fi

# Longrun to run upgrade on Satellite, capsule and clients
fab -u root product_upgrade:'longrun'
