pip install -r requirements.txt

source ${FAKE_CERT_CONFIG}
source ${INSTALL_CONFIG}
source ${PROVISIONING_CONFIG}
source ${PROXY_CONFIG}

if [ "${STAGE_TEST}" = 'false' ]; then
    source ${SUBSCRIPTION_CONFIG}
else
    source ${STAGE_CONFIG}
fi

export SERVER_HOSTNAME="${TARGET_IMAGE}.${VM_DOMAIN}"

# For example: The target_image in PROVISIONING_CONFIG file should be "qe-sat6y-rhel7-base".
BTARGET_IMAGE="${TARGET_IMAGE}"
# Remove "-base" suffix for hostname.
TARGET_IMAGE=`echo ${TARGET_IMAGE} | cut -d '-' -f1-3`
# Update SERVER_HOSTNAME for the snapshot based pipelines
export SERVER_HOSTNAME="${TARGET_IMAGE}.${VM_DOMAIN}"
set +e
fab -H "root@${PROVISIONING_HOST}" "vm_destroy:target_image=${TARGET_IMAGE},delete_image=true"
set -e
# Revert the target_image name for creating and destroying of the base-image.
export TARGET_IMAGE="${BTARGET_IMAGE}"

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
fi

# Write a properties file to allow passing variables to other build steps
echo "SERVER_HOSTNAME=${SERVER_HOSTNAME}" > build_env.properties
echo "TOOLS_REPO=${TOOLS_URL}" >> build_env.properties
echo "SUBNET=${SUBNET}" >> build_env.properties
echo "NETMASK=${NETMASK}" >> build_env.properties
echo "GATEWAY=${GATEWAY}" >> build_env.properties
echo "BRIDGE=${BRIDGE}" >> build_env.properties
echo "DISCOVERY_ISO=${DISCOVERY_ISO}" >> build_env.properties


# POLARION_RELEASE depends upon SATELLITE_VERSION
if [ "${SATELLITE_VERSION}" = "6.3" ]; then
    ZRELEASE='0'
else
    ZRELEASE='z'
fi

if [ "${SATELLITE_VERSION}" = "nightly" ]; then
    echo "POLARION_RELEASE='Upstream Nightly'" >> build_env.properties
elif [ "${SATELLITE_VERSION}" != "nightly" ]; then
    echo "POLARION_RELEASE='Satellite ${SATELLITE_VERSION}.${ZRELEASE}'" >> build_env.properties
fi

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
echo "Shutting down the Base instance of ${SERVER_HOSTNAME} gracefully"
# Shutdown the Satellite6 services before shutdown.
ssh -o StrictHostKeyChecking=no root@"${SERVER_HOSTNAME}" katello-service stop
# Try to shutdown the Satellite6 instance gracefully and sleep for a while.
ssh -o StrictHostKeyChecking=no root@"${PROVISIONING_HOST}" virsh shutdown ${TARGET_IMAGE}
sleep 120
set +e
# Destroy the sat6 instance anyways if for some reason virsh shutdown couldn't gracefully shut it down.
ssh -o StrictHostKeyChecking=no root@"${PROVISIONING_HOST}" virsh destroy ${TARGET_IMAGE}
set -e
echo "========================================"
