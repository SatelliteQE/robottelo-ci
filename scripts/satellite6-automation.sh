pip install -U -r requirements.txt docker-py pytest-xdist

cp config/robottelo.properties ./robottelo.properties

sed -i "s/{server_hostname}/${SERVER_HOSTNAME}/" robottelo.properties
sed -i "s|# screenshots_path=.*|screenshots_path=$(pwd)/screenshots|" robottelo.properties
sed -i "s|external_url=.*|external_url=http://${SERVER_HOSTNAME}:2375|" robottelo.properties
sed -i "s/# bz_password=.*/bz_password=${BUGZILLA_PASSWORD}/" robottelo.properties
sed -i "s/# bz_username=.*/bz_username=${BUGZILLA_USER}/" robottelo.properties

# Robottelo logging configuration
sed -i "s/'\(robottelo\).log'/'\1-${ENDPOINT}.log'/" logging.conf

# upstream = 1 for Distributions: UPSTREAM (default in robottelo.properties)
# upstream = 0 for Distributions: DOWNSTREAM, CDN, BETA, ISO
if [[ "${SATELLITE_DISTRIBUTION}" != *"nightly"* ]]; then
   sed -i "s/^upstream.*/upstream=false/" robottelo.properties
    if [[ "${SATELLITE_DISTRIBUTION}" != *"GA"* ]]; then
       sed -i "s/^# \[vlan_networking\].*/[vlan_networking]/" robottelo.properties
       sed -i "s/^# subnet.*/subnet=${SUBNET}/" robottelo.properties
       sed -i "s/^# netmask.*/netmask=${NETMASK}/" robottelo.properties
       sed -i "s/^# gateway.*/gateway=${GATEWAY}/" robottelo.properties
       sed -i "s/^# bridge.*/bridge=${BRIDGE}/" robottelo.properties
       # To set the discovery ISO name in properties file
       sed -i "s/^# \[discovery\].*/[discovery]/" robottelo.properties
       sed -i "s/^# discovery_iso.*/discovery_iso=${DISCOVERY_ISO}/" robottelo.properties
    fi
fi

# cdn = 1 for Distributions: GA (default in robottelo.properties)
# cdn = 0 for Distributions: INTERNAL, BETA, ISO
# Sync content and use the below repos only when DISTRIBUTION is not GA
if [[ "${SATELLITE_DISTRIBUTION}" != *"GA"* ]]; then
    # The below cdn flag is required by automation to flip between RH & custom syncs.
    sed -i "s/cdn.*/cdn=0/" robottelo.properties
    # Usage of '|' is intentional as TOOLS_REPO can bring in http url which has '/'
    sed -i "s|sattools_repo.*|sattools_repo=${TOOLS_REPO}|" robottelo.properties
fi

if [ "${ENDPOINT}" != "rhai" ]; then
    set +e
    # Run parallel tests
    $(which py.test) -v --junit-xml="${ENDPOINT}-parallel-results.xml" -n "${ROBOTTELO_WORKERS}" \
        -m "${ENDPOINT} and not run_in_one_thread and not stubbed" \
        tests/foreman/{api,cli,ui,longrun}

    # Run sequential tests
    $(which py.test) -v --junit-xml="${ENDPOINT}-sequential-results.xml" \
        -m "${ENDPOINT} and run_in_one_thread and not stubbed" \
        tests/foreman/{api,cli,ui,longrun}
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
