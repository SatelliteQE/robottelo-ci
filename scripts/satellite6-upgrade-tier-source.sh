pip install -U -r requirements.txt docker-py pytest-xdist sauceclient
 # Sourcing and exporting required env vars for tier jobs
source ${CONFIG_FILES}
source config/compute_resources.conf
source config/sat6_upgrade.conf
export SERVER_HOSTNAME="${SERVER_HOSTNAME:-${RHEV_SAT_HOST}}"


cp config/robottelo.properties ./robottelo.properties

sed -i "s/{server_hostname}/${SERVER_HOSTNAME}/" robottelo.properties
sed -i "s|# screenshots_path=.*|screenshots_path=$(pwd)/screenshots|" robottelo.properties
sed -i "s|external_url=.*|external_url=http://${SERVER_HOSTNAME}:2375|" robottelo.properties

# Sauce Labs Configuration

if [[ "${SAUCE_PLATFORM}" != "no_saucelabs" ]]; then
    echo "The Sauce Tunnel Identifier for Server Hostname ${SERVER_HOSTNAME} is ${TUNNEL_IDENTIFIER}"
    sed -i "s/^browser.*/browser=saucelabs/" robottelo.properties
    sed -i "s/^# saucelabs_user=.*/saucelabs_user=${SAUCELABS_USER}/" robottelo.properties
    sed -i "s/^# saucelabs_key=.*/saucelabs_key=${SAUCELABS_KEY}/" robottelo.properties
    sed -i "s/^# webdriver=.*/webdriver=${SAUCE_BROWSER}/" robottelo.properties
    if [[ "${SAUCE_BROWSER}" == "firefox" ]]; then
        BROWSER_VERSION=45.0
    elif [[ "${SAUCE_BROWSER}" == "edge" ]]; then
        BROWSER_VERSION=14.14393
    fi
    sed -i "s/^# webdriver_desired_capabilities=.*/webdriver_desired_capabilities=platform=${SAUCE_PLATFORM},version=${BROWSER_VERSION},idleTimeout=1000,seleniumVersion=2.48.0,build=${BUILD_LABEL},screenResolution=1600x1200,tunnelIdentifier=${TUNNEL_IDENTIFIER}/" robottelo.properties
fi

# Bugzilla Login Details

sed -i "s/# bz_password=.*/bz_password=${BUGZILLA_PASSWORD}/" robottelo.properties
sed -i "s/# bz_username=.*/bz_username=${BUGZILLA_USER}/" robottelo.properties

# AWS Access Keys Configuration

sed -i "s/# access_key=.*/access_key=${AWS_ACCESSKEY_ID}/" robottelo.properties
sed -i "s|# secret_key=.*|secret_key=${AWS_ACCESSKEY_SECRET}|" robottelo.properties

# Robottelo Capsule Configuration

sed -i "s/^# \[capsule\].*/[capsule]/" robottelo.properties
sed -i "s/^# instance_name=.*/instance_name=${SERVER_HOSTNAME%%.*}-capsule/" robottelo.properties
sed -i "s/^# domain=.*/domain=${DDNS_DOMAIN}/" robottelo.properties
sed -i "s/^# hash=.*/hash=${CAPSULE_DDNS_HASH}/" robottelo.properties
sed -i "s|^# ddns_package_url=.*|ddns_package_url=${DDNS_PACKAGE_URL}|" robottelo.properties

if [ -n "${IMAGE}" ]; then
    sed -i "s/^# \[distro\].*/[distro]/" robottelo.properties
    sed -i "s/^# image_el6=.*/image_el6=${IMAGE}/" robottelo.properties
    sed -i "s/^# image_el7=.*/image_el7=${IMAGE}/" robottelo.properties
fi

# Robottelo logging configuration
sed -i "s/'\(robottelo\).log'/'\1-${ENDPOINT}.log'/" logging.conf

# upstream = 1 for Distributions: UPSTREAM (default in robottelo.properties)
# upstream = 0 for Distributions: DOWNSTREAM, CDN, BETA, ISO
if [[ "${SATELLITE_VERSION}" != *"upstream-nightly"* ]]; then
   sed -i "s/^upstream=.*/upstream=false/" robottelo.properties
   sed -i "s/^# \[vlan_networking\].*/[vlan_networking]/" robottelo.properties
   sed -i "s/^# subnet=.*/subnet=${SUBNET}/" robottelo.properties
   sed -i "s/^# netmask=.*/netmask=${NETMASK}/" robottelo.properties
   sed -i "s/^# gateway=.*/gateway=${GATEWAY}/" robottelo.properties
   sed -i "s/^# bridge=.*/bridge=${BRIDGE}/" robottelo.properties
   # To set the discovery ISO name in properties file
   sed -i "s/^# \[discovery\].*/[discovery]/" robottelo.properties
   sed -i "s/^# discovery_iso=.*/discovery_iso=${DISCOVERY_ISO}/" robottelo.properties
fi

# cdn = 1 for Distributions: GA (default in robottelo.properties)
# cdn = 0 for Distributions: INTERNAL, BETA, ISO
# Sync content and use the below repos only when DISTRIBUTION is not GA
if [[ "${SATELLITE_DISTRIBUTION}" != *"GA"* ]]; then
    # The below cdn flag is required by automation to flip between RH & custom syncs.
    sed -i "s/cdn.*/cdn=false/" robottelo.properties
    # Usage of '|' is intentional as TOOLS_REPO can bring in http url which has '/'
    sed -i "s|sattools_repo=.*|sattools_repo=rhel7=${RHEL7_TOOLS_REPO},rhel6=${RHEL6_TOOLS_REPO}|" robottelo.properties
    sed -i "s|capsule_repo=.*|capsule_repo=${CAPSULE_REPO}|" robottelo.properties
fi

if [[ "${SATELLITE_VERSION}" != "6.1" ]]; then
    TEST_TYPE="$(echo tests/foreman/{api,cli,ui,longrun,sys,installer})"
else
    TEST_TYPE="$(echo tests/foreman/{api,cli,ui,longrun})"
fi

if [ "${ENDPOINT}" != "end-to-end" ]; then
    set +e
    # Run all sequential tests with upgrade mark
    $(which py.test) -v --junit-xml="upgrade-sequential-results.xml" \
        -m "upgrade and run_in_one_thread and not stubbed" \
        ${TEST_TYPE}

    # Run all parallel tests with upgrade mark
    $(which py.test) -v --junit-xml="upgrade-parallel-results.xml" -n "${ROBOTTELO_WORKERS}" \
        -m "upgrade and not run_in_one_thread and not stubbed" \
        ${TEST_TYPE}
    set -e
elif [ "${ENDPOINT}" == "end-to-end" ]; then
    set +e
    # Run end-to-end , also known as smoke tests
    $(which py.test) -v --junit-xml="smoke-tests-results.xml" tests/foreman/endtoend
    set -e

else
    make test-foreman-${ENDPOINT} PYTEST_XDIST_NUMPROCESSES=${ROBOTTELO_WORKERS}
fi
if [ "${ROBOTTELO_WORKERS}" -gt 0 ]; then
    make logs-join
    make logs-clean
fi

echo
echo "========================================"
echo "Server information"
echo "========================================"
echo "Hostname: ${SERVER_HOSTNAME}"
echo "Credentials: admin/changeme"
echo "========================================"
echo
echo "========================================"

