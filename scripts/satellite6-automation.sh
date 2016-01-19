pip install -U -r requirements.txt docker-py pytest-xdist

cp ${ROBOTTELO_CONFIG} ./robottelo.properties

sed -i "s/{server_hostname}/${SERVER_HOSTNAME}/" robottelo.properties

# Robottelo logging configuration
sed -i "s/'\(robottelo\).log'/'\1-${ENDPOINT}.log'/" logging.conf

# upstream = 1 for Distributions: UPSTREAM (default in robottelo.properties)
# upstream = 0 for Distributions: DOWNSTREAM, CDN, BETA, ISO
if [[ "${DISTRIBUTION}" != *"upstream"* ]]; then
   sed -i "s/^upstream.*/upstream=false/" robottelo.properties
    if [[ "${DISTRIBUTION}" != *"cdn"* ]]; then
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

# cdn = 1 for Distributions: CDN (default in robottelo.properties)
# cdn = 0 for Distributions: DOWNSTREAM, BETA, ISO, ZSTREAM
# Sync content and use the below repos only when DISTRIBUTION is not CDN
if [[ "${DISTRIBUTION}" != *"cdn"* ]]; then
    # The below cdn flag is required by automation to flip between RH & custom syncs.
    sed -i "s/cdn.*/cdn=0/" robottelo.properties
    # Usage of '|' is intentional as TOOLS_REPO can bring in http url which has '/'
    sed -i "s|sattools_repo.*|sattools_repo=${TOOLS_REPO}|" robottelo.properties
fi

make test-foreman-${ENDPOINT} PYTEST_XDIST_NUMPROCESSES=4
