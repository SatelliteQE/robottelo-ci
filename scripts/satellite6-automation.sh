# Zstream Job requires it's own requirements and the versions are freezed.
if [ "${DISTRIBUTION}" = "satellite6-zstream" ]; then
    pip install -U -r requirements-freeze.txt
else
    pip install -U -r requirements.txt docker-py pytest-xdist
fi

source ${PROVISIONING_CONFIG}

# Provisioning jobs TARGET_IMAGE becomes the SOURCE_IMAGE for Tier and RHAI jobs.
export SOURCE_IMAGE="${TARGET_IMAGE}"
export TARGET_IMAGE=`echo ${TARGET_IMAGE} | cut -d '-' -f1-3`

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

function setup_instance () {
    # Provision the instance using satellite6 base image as the source image.
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@"${PROVISIONING_HOST}" \
    snap-guest -b "${SOURCE_IMAGE}" -t "${TARGET_IMAGE}" --hostname "${TARGET_IMAGE}.${VM_DOMAIN}" \
    -m "${VM_RAM}" -c "${VM_CPU}" -d "${VM_DOMAIN}" -f -n bridge="${BRIDGE}" --static-ipaddr "${IPADDR}" \
    --static-netmask "${NETMASK}" --static-gateway "${GATEWAY}"

    # Let's wait for 60 secs for the instance to be up and along with it it's services
    sleep 60

    # SSH into the instance to fetch hostname and make sure it is up and running or loop 7 time.
    count=1; while [ $count -le 7 ]; do echo "Trying to ssh to ${TARGET_IMAGE}.${VM_DOMAIN}"; (( count++ )); \
    sleep $count ; ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -T \
    root@"${TARGET_IMAGE}.${VM_DOMAIN}" hostname  && break; if [ $count -eq 8 ]; then exit; fi done

    # SELINUX fix required as after reboot the iptable information is lost. Temporary fix.
    ssh -o StrictHostKeyChecking=no root@"${TARGET_IMAGE}.${VM_DOMAIN}" 'iptables -F'

    # Restart Satellite6 service for a clean state of the running instance.
    ssh -o StrictHostKeyChecking=no root@"${TARGET_IMAGE}.${VM_DOMAIN}" 'katello-service restart'
}

remove_instance
setup_instance

cp ${ROBOTTELO_CONFIG} ./robottelo.properties

sed -i "s/{server_hostname}/${SERVER_HOSTNAME}/" robottelo.properties
sed -i "s|# screenshots_path=.*|screenshots_path=$(pwd)/screenshots|" robottelo.properties
sed -i "s|external_url=.*|external_url=http://${SERVER_HOSTNAME}:2375|" robottelo.properties

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

if [ "${CLEANUP_SATELLITE_ORGS}" = 'true' ]; then
    sed -i "s/^# cleanup.*/cleanup=true/" robottelo.properties
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
echo "Delete the instance of: ${SERVER_HOSTNAME}"

remove_instance
# After rhai is run, let's setup_instance once again for a clean state,
# so that we can do bug or feature testing if needed on this instance.
if [ "${ENDPOINT}" == "rhai" ]; then
    setup_instance
fi
