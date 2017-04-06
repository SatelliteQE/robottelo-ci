pip install -r requirements.txt

source ${CONFIG_FILES}
source config/fake_manifest.conf
source config/auth_servers.conf
source config/installation_environment.conf
source config/provisioning_environment.conf
source config/proxy_config_environment.conf
source config/subscription_config.conf
if [ "${STAGE_TEST}" = 'true' ]; then
    source config/stage_environment.conf
fi
if [ "${PUPPET4}" = 'true' ]; then
    export PUPPET4_REPO # sourced from installation_environment.conf
fi

export EXTERNAL_AUTH
export HOTFIX
export IDM_REALM

# The target_image in provisioning_environment.conf should be "qe-sat6y-rhel7-base".
export TARGET_IMAGE
# set SERVER_HOSTNAME for the snapshot based pipelines by removing "-base" suffix if there is one
export SERVER_HOSTNAME="${TARGET_IMAGE%%-base}.${VM_DOMAIN}"
set +e
fab -H "root@${PROVISIONING_HOST}" "vm_destroy:target_image=${TARGET_IMAGE},delete_image=true"
for endpoint in tier1 tier2 tier3 tier4 rhai; do fab -H "root@${PROVISIONING_HOST}" "vm_destroy:target_image=${TARGET_IMAGE%%-base}-$endpoint,delete_image=true"; done
set -e

# Assign DISTRIBUTION to trigger things appropriately from automation-tools.
if [ "${SATELLITE_DISTRIBUTION}" = 'INTERNAL' ]; then
    export DISTRIBUTION="satellite6-downstream"
elif [ "${SATELLITE_DISTRIBUTION}" = 'GA' ]; then
    export DISTRIBUTION="satellite6-cdn"
elif [ "${SATELLITE_DISTRIBUTION}" = 'BETA' ]; then
    export DISTRIBUTION="satellite6-beta"
elif [ "${SATELLITE_DISTRIBUTION}" = 'UPSTREAM' ]; then
    export DISTRIBUTION="satellite6-upstream"
elif [ "${SATELLITE_DISTRIBUTION}" = 'INTERNAL REPOFILE' ]; then
    export DISTRIBUTION="satellite6-repofile"
elif [ "${SATELLITE_DISTRIBUTION}" = 'INTERNAL AK' ]; then
    export DISTRIBUTION="satellite6-activationkey"
elif [ "${SATELLITE_DISTRIBUTION}" = "ISO" ]; then
    export DISTRIBUTION="satellite6-iso"
fi

# ISOs require a specific URL
if [ "${SATELLITE_DISTRIBUTION}" = "ISO" ]; then
    if [ ! -z "${BASE_URL}" ]; then
        export ISO_URL="${BASE_URL}"
    else
        export ISO_URL="${SATELLITE6_ISO_REPO}"
    fi
fi

# Write a properties file to allow passing variables to other build steps
echo "SERVER_HOSTNAME=${SERVER_HOSTNAME}" > build_env.properties
echo "SATELLITE_DISTRIBUTION=${SATELLITE_DISTRIBUTION}" >> build_env.properties
echo "TOOLS_REPO=${TOOLS_URL}" >> build_env.properties
echo "SUBNET=${SUBNET}" >> build_env.properties
echo "NETMASK=${NETMASK}" >> build_env.properties
echo "GATEWAY=${GATEWAY}" >> build_env.properties
echo "BRIDGE=${BRIDGE}" >> build_env.properties
echo "DISCOVERY_ISO=${DISCOVERY_ISO}" >> build_env.properties

# Run installation after writing the build_env.properties to make sure the
# values are available for the post build actions, specially the foreman-debug
# capturing.
fab -H "root@${PROVISIONING_HOST}" "product_install:${DISTRIBUTION},create_vm=true,sat_cdn_version=${SATELLITE_VERSION},test_in_stage=${STAGE_TEST}"

echo
echo "========================================"
echo "Server information"
echo "========================================"
echo "Hostname: ${SERVER_HOSTNAME}"
echo "Credentials: admin/changeme"
echo "========================================"
echo
echo "========================================"
