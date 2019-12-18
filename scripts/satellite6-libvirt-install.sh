pip install -r requirements.txt

source ${CONFIG_FILES}

if [ -n "${DISTRO}" ]; then
    export OS_VERSION="${DISTRO}"
fi

source config/fake_manifest.conf
source config/installation_environment.conf
source config/auth_servers.conf
source config/provision_libvirt_install.conf
source config/proxy_config_environment.conf
source config/subscription_config.conf
source config/sat6_repos_urls.conf
source config/compute_resources.conf

if [ "$TEMPORARY_FIXES" = 'true' ]; then
    source config/temporary_fixes.conf
fi

if [ "${STAGE_TEST}" = 'true' ]; then
    source config/stage_environment.conf
fi

# If no SERVER_ID is selected from the Job and is 'no_server_id'.
# As BRIDGE value is picked up from provision_libvirt_install.conf file.
if [[ -z "${BRIDGE}" ]]; then
    exit 1
fi

export EXTERNAL_AUTH
export IDM_REALM

function remove_instance () {
    # For Example: The TARGET_IMAGE in provision_libvirt_install.conf should be "qe-test-rhel7".
    export TARGET_IMAGE
    export SERVER_HOSTNAME="${TARGET_IMAGE}.${VM_DOMAIN}"
    set +e
    fab -D -H "root@$1" "vm_destroy:target_image=${TARGET_IMAGE},delete_image=true"
    set -e
}

# Clean up the running instances on all the hosts, if any. This is required so that there is no
# IP conflict, while provisioning the host on a different PROVISIONING_HOST.
for host in ${CLEANUP_PROVISIONING_HOSTS} ; do remove_instance $host; done

# Assign DISTRIBUTION to trigger things appropriately from automation-tools.
if [ "${SATELLITE_DISTRIBUTION}" = 'INTERNAL' ]; then
    export DISTRIBUTION="satellite6-downstream"
elif [ "${SATELLITE_DISTRIBUTION}" = 'GA' ]; then
    export DISTRIBUTION="satellite6-cdn"
elif [ "${SATELLITE_DISTRIBUTION}" = 'INTERNAL REPOFILE' ]; then
    export DISTRIBUTION="satellite6-repofile"
elif [ "${SATELLITE_DISTRIBUTION}" = 'INTERNAL AK' ]; then
    export DISTRIBUTION="satellite6-activationkey"
fi

fab -D -H "root@${PROVISIONING_HOST}" "vm_create:target_image=${TARGET_IMAGE},source_image=${SOURCE_IMAGE},bridge=${BRIDGE}"
fab -D -H "root@${SERVER_HOSTNAME}" "product_install:${DISTRIBUTION},sat_version=${SATELLITE_VERSION},test_in_stage=${STAGE_TEST}"

echo
echo "========================================"
echo "Server information"
echo "========================================"
echo "Hostname: ${SERVER_HOSTNAME}"
echo "Credentials: admin/changeme"
echo "========================================"

# Download the Satellite6 Configure Template.
wget https://raw.githubusercontent.com/SatelliteQE/robottelo-ci/master/scripts/satellite6-populate-template.sh
wget https://raw.githubusercontent.com/SatelliteQE/robottelo-ci/master/scripts/satellite6-provision-host-template.sh

cp satellite6-populate-template.sh satellite6-populate.sh
chmod 755 satellite6-populate.sh

export SUBNET_RANGE="${SUBNET}"
export SUBNET_MASK="${NETMASK}"
export SUBNET_GATEWAY="${GATEWAY}"
