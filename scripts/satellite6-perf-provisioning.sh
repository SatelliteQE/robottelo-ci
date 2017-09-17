pip install -r requirements.txt

source ${CONFIG_FILES}
source config/provision_perf_install.conf

function manage_instances () {
    set +e
    fab -D -H "root@${PROVISIONING_HOST}" "vm_destroy:target_image=${TARGET_IMAGE},delete_image=true"
    set -e

    # Run installation after writing the build_env.properties to make sure the
    # values are available for the post build actions.
    fab -D -H "root@${PROVISIONING_HOST}" vm_create
}

export IPADDR="${SATELLITE_IPADDR}"
export NETMASK="${SATELLITE_NETMASK}"
export TARGET_IMAGE="${SATELLITE_TARGET_IMAGE}"
export DDNS_HASH="${SATELLITE_DDNS_HASH}"

manage_instances

# Write a properties file to allow passing variables to other build steps
SATELLITE_SERVER_HOSTNAME="${TARGET_IMAGE}.${VM_DOMAIN}"
echo "SATELLITE_SERVER_HOSTNAME=${SATELLITE_SERVER_HOSTNAME=}" > build_env.properties


export IPADDR="${CAPSULE_IPADDR}"
export NETMASK="${CAPSULE_NETMASK}"
export TARGET_IMAGE="${CAPSULE_TARGET_IMAGE}"
export DDNS_HASH="${CAPSULE_DDNS_HASH}"

manage_instances

# Write a properties file to allow passing variables to other build steps
CAPSULE_SERVER_HOSTNAME="${TARGET_IMAGE}.${VM_DOMAIN}"
echo "CAPSULE_SERVER_HOSTNAME=${CAPSULE_SERVER_HOSTNAME}" >> build_env.properties

echo
echo "========================================"
echo "Server information"
echo "========================================"
echo "Satellite Hostname: ${SATELLITE_SERVER_HOSTNAME}"
echo "Capsule Hostname: ${CAPSULE_SERVER_HOSTNAME}"
echo "========================================"
echo
