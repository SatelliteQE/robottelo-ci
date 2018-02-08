pip install -r requirements.txt

source ${CONFIG_FILES}
source config/fake_manifest.conf
source config/installation_environment.conf
source config/auth_servers.conf
source config/client-automation.conf
source config/proxy_config_environment.conf
source config/subscription_config.conf
source config/sat6_repos_urls.conf
source config/compute_resources.conf


# Assign DISTRIBUTION to trigger things appropriately from automation-tools.
if [ "${SATELLITE_INSTALL_DISTRIBUTION}" = 'INTERNAL' ]; then
    export DISTRIBUTION="satellite6-downstream"
elif [ "${SATELLITE_INSTALL_DISTRIBUTION}" = 'GA' ]; then
    export DISTRIBUTION="satellite6-cdn"
elif [ "${SATELLITE_INSTALL_DISTRIBUTION}" = 'INTERNAL REPOFILE' ]; then
    export DISTRIBUTION="satellite6-repofile"
elif [ "${SATELLITE_INSTALL_DISTRIBUTION}" = 'INTERNAL AK' ]; then
    export DISTRIBUTION="satellite6-activationkey"
elif [ "${SATELLITE_INSTALL_DISTRIBUTION}" = 'BETA' ]; then
    export DISTRIBUTION="satellite6-beta"
fi


if [ -z "${SERVER_HOSTNAME}" ]; then
    set +e
    fab -D -H "root@${PROVISIONING_HOST}" "vm_destroy:target_image=${TARGET_IMAGE},delete_image=true"
    set -e
    fab -D -H "root@${PROVISIONING_HOST}" "product_install:${DISTRIBUTION},create_vm=true,sat_cdn_version=${SATELLITE_VERSION},test_in_stage=${STAGE_TEST}"
    export SERVER_HOSTNAME="${TARGET_IMAGE}.${VM_DOMAIN}"
fi


echo
echo "========================================"
echo "Server information"
echo "========================================"
echo "Hostname: ${SERVER_HOSTNAME}"
echo "Credentials: admin/changeme"
echo "========================================"
