pip install -r requirements.txt

source ${CONFIG_FILES}
source config/fake_manifest.conf
source config/installation_environment.conf
source config/provisioning_environment.conf
source config/proxy_config_environment.conf
source config/subscription_config.conf
if [ "${STAGE_TEST}" = 'true' ]; then
    source config/stage_environment.conf
fi

# The target_image in provisioning_environment.conf should be "qe-sat6y-rhel7-base".
export TARGET_IMAGE
# set SERVER_HOSTNAME for the snapshot based pipelines by removing "-base" suffix if there is one
export SERVER_HOSTNAME="${TARGET_IMAGE%%-base}.${VM_DOMAIN}"
set +e
fab -H "root@${PROVISIONING_HOST}" "vm_destroy:target_image=${TARGET_IMAGE%%-base},delete_image=true"
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
    echo "POLARION_RELEASE=Upstream Nightly" >> build_env.properties
elif [ "${SATELLITE_VERSION}" != "nightly" ]; then
    echo "POLARION_RELEASE=Satellite ${SATELLITE_VERSION}.${ZRELEASE}" >> build_env.properties
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


# Remove any previous instances of foreman-debug tar file
rm -rf foreman-debug.tar.xz
# Disable error checking, for more information check the related issue
# http://projects.theforeman.org/issues/13442
# Let's continue to use this till we stop testing Satellite6.1 completely.
set +e
ssh "root@${SERVER_HOSTNAME}" foreman-debug -g -q -d "~/foreman-debug"
set -e
scp -r "root@${SERVER_HOSTNAME}:~/foreman-debug.tar.xz" .


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
