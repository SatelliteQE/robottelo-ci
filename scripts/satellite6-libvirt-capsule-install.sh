pip install -r requirements.txt

source ${CONFIG_FILES}
source config/installation_environment.conf
source config/provision_libvirt_install.conf
source config/provision_satellite_capsule_install.conf


# If no SERVER_ID is selected from the Job and is 'no_server_id'.
# As BRIDGE value is picked up from provision_libvirt_install.conf file.
if [[ -z "${BRIDGE}" ]]; then
    exit 1
fi

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


fab -D -H "root@${PROVISIONING_HOST}" "vm_create"

echo
echo "========================================"
echo "Satellite and Capsule Server information"
echo "========================================"
echo "Satellite Hostname: ${SATELLITE_SERVER_HOSTNAME}"
echo "Capsule Hostname: ${SERVER_HOSTNAME}"
echo "Credentials: admin/changeme"
echo "========================================"

export SUBNET_RANGE="${SUBNET}"
export SUBNET_MASK="${NETMASK}"
export SUBNET_GATEWAY="${GATEWAY}"

export CAPSULE_FQDN="${SERVER_HOSTNAME}"
export SATELLITE_FQDN="${SATELLITE_SERVER_HOSTNAME}"

fab -t 60 -D -H "root@${SATELLITE_FQDN}" "generate_capsule_certs"

fab -D -H "root@${CAPSULE_FQDN}" "setup_capsule"
