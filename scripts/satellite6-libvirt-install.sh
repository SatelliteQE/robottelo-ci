pip install -r requirements.txt

source ${CONFIG_FILES}
source config/fake_manifest.conf
source config/installation_environment.conf
source config/provision_libvirt_install.conf
source config/proxy_config_environment.conf
source config/subscription_config.conf
if [ "${STAGE_TEST}" = 'true' ]; then
    source config/stage_environment.conf
fi

# For Example: The TARGET_IMAGE in provision_libvirt_install.conf should be "qe-testing-rhel7".
export TARGET_IMAGE
set +e
fab -H "root@${PROVISIONING_HOST}" "vm_destroy:target_image=${TARGET_IMAGE},delete_image=true"
set -e

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

# Write a properties file to allow passing variables to other build steps
echo "SERVER_HOSTNAME=${SERVER_HOSTNAME}" > build_env.properties
echo "TOOLS_REPO=${TOOLS_URL}" >> build_env.properties
echo "SUBNET=${SUBNET}" >> build_env.properties
echo "NETMASK=${NETMASK}" >> build_env.properties
echo "GATEWAY=${GATEWAY}" >> build_env.properties
echo "BRIDGE=${BRIDGE}" >> build_env.properties

# Run installation after writing the build_env.properties to make sure the
# values are available for the post build actions, specially the foreman-debug
# capturing.
fab -H "root@${PROVISIONING_HOST}" "product_install:${DISTRIBUTION},create_vm=true,sat_cdn_version=${SAT_VERSION},test_in_stage=${STAGE_TEST}"

echo
echo "========================================"
echo "Server information"
echo "========================================"
echo "Hostname: ${SERVER_HOSTNAME}"
echo "Credentials: admin/changeme"
echo "========================================"
