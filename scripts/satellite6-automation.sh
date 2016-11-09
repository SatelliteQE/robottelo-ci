# Zstream Job requires it's own requirements and the versions are freezed.
if [ -f requirements-freeze.txt ]; then
    pip install -U -r requirements-freeze.txt
else
    pip install -U -r requirements.txt docker-py pytest-xdist
fi


function remove_instance () {
    echo "========================================"
    echo " Remove any running instances if any of ${TARGET_IMAGE} virsh domain."
    echo "========================================"
    set +e
    ssh -o StrictHostKeyChecking=no root@"${PROVISIONING_HOST}" virsh destroy ${TARGET_IMAGE}
    ssh -o StrictHostKeyChecking=no root@"${PROVISIONING_HOST}" virsh undefine ${TARGET_IMAGE}
    ssh -o StrictHostKeyChecking=no root@"${PROVISIONING_HOST}" virsh vol-delete --pool default /var/lib/libvirt/images/${TARGET_IMAGE}.img
    set -e
}


function destroy_instance () {
    echo "========================================"
    echo " Destroy any running instances if any of ${TARGET_IMAGE} virsh domain."
    echo "========================================"
    set +e
    ssh -o StrictHostKeyChecking=no root@"${PROVISIONING_HOST}" virsh destroy ${TARGET_IMAGE}
    set -e
}

function setup_instance () {
    # Provision the instance using satellite6 base image as the source image.
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@"${PROVISIONING_HOST}" \
    snap-guest -b "${SOURCE_IMAGE}" -t "${TARGET_IMAGE}" --hostname "${TARGET_IMAGE}.${VM_DOMAIN}" \
    -m "${VM_RAM}" -c "${VM_CPU}" -d "${VM_DOMAIN}" -f -n bridge="${BRIDGE}" --static-ipaddr "${IPADDR}" \
    --static-netmask "${NETMASK}" --static-gateway "${GATEWAY}"

    # Let's wait for 60 secs for the instance to be up and along with it it's services
    sleep 60

    # Restart Satellite6 service for a clean state of the running instance.
    ssh -o StrictHostKeyChecking=no root@"${TARGET_IMAGE}.${VM_DOMAIN}" 'katello-service restart'
}

source ${CONFIG_FILES}
source config/provisioning_environment.conf
# Provisioning jobs TARGET_IMAGE becomes the SOURCE_IMAGE for Tier and RHAI jobs.
export SOURCE_IMAGE="${TARGET_IMAGE}"
export TARGET_IMAGE="${TARGET_IMAGE%%-base}-${ENDPOINT}"

remove_instance
setup_instance

cp config/robottelo.properties ./robottelo.properties

sed -i "s/{server_hostname}/${SERVER_HOSTNAME}/" robottelo.properties
sed -i "s|# screenshots_path=.*|screenshots_path=$(pwd)/screenshots|" robottelo.properties
sed -i "s|external_url=.*|external_url=http://${SERVER_HOSTNAME}:2375|" robottelo.properties

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


# Remove any previous instances of foreman-debug tar file
rm -rf foreman-debug.tar.xz
# Disable error checking, for more information check the related issue
# http://projects.theforeman.org/issues/13442
# Let's continue to use this till we stop testing Satellite6.1 completely.
set +e
ssh "root@${SERVER_HOSTNAME}" foreman-debug -g -q -d "~/foreman-debug"
set -e
scp -r "root@${SERVER_HOSTNAME}:~/foreman-debug.tar.xz" .


echo "Deleting the instance of: ${SERVER_HOSTNAME}"
# Only destroy the instance so that we can start up the instance if required for testcase
# analysis.
destroy_instance

# After rhai is run, let's setup_instance once again for a clean state,
# so that we can do bug or feature testing if needed on this instance.
if [ "${ENDPOINT}" == "rhai" ]; then
    # Create a generic instance from the base image and not modify the rhai image.
    TARGET_IMAGE="${TARGET_IMAGE%%-rhai}"
    remove_instance
    setup_instance
fi
