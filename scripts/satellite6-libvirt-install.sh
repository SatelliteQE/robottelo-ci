pip install -r requirements.txt

source ${CONFIG_FILES}
source config/fake_manifest.conf
source config/installation_environment.conf
source config/provision_libvirt_install.conf
source config/proxy_config_environment.conf
source config/subscription_config.conf
source config/sat6_repos_urls.conf
if [ "${STAGE_TEST}" = 'true' ]; then
    source config/stage_environment.conf
fi

# For Example: The TARGET_IMAGE in provision_libvirt_install.conf should be "qe-test-rhel7".
export TARGET_IMAGE
export SERVER_HOSTNAME="${TARGET_IMAGE}.${VM_DOMAIN}"
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

fab -H "root@${PROVISIONING_HOST}" "product_install:${DISTRIBUTION},create_vm=true,sat_cdn_version=${SATELLITE_VERSION},test_in_stage=${STAGE_TEST}"

echo
echo "========================================"
echo "Server information"
echo "========================================"
echo "Hostname: ${SERVER_HOSTNAME}"
echo "Credentials: admin/changeme"
echo "========================================"

# Download the Satellite6 Configure Template.
#wget ${HTTP_SERVER_HOSTNAME}/pub/sat6_configure_template.sh

echo
echo "============================================="
echo "Populating template to configure Satellite6 "
echo "============================================="
echo

cp sat6_configure_template.sh sat6_configure.sh
chmod 755 sat6_configure.sh

# Update the subnet information
sed -i "s|SUBNET_NAME=.*|SUBNET_NAME=${SUBNET}|" sat6_configure.sh
sed -i "s|SUBNET_IP=.*|SUBNET_IP=${IPADDR}|" sat6_configure.sh
sed -i "s|SUBNET_MASK=.*|SUBNET_MASK=${NETMASK}|" sat6_configure.sh
sed -i "s|SUBNET_GATEWAY=.*|SUBNET_GATEWAY=${GATEWAY}|" sat6_configure.sh

# Updates the REPO URLS automatically depending upon the satellite6 version choosen in the job.
# This is done by using the already maintained sat6_repo_url config file.
sed -i "s|RHEL6_TOOLS_URL=.*|RHEL6_TOOLS_URL=${TOOLS_RHEL6}|" sat6_configure.sh
sed -i "s|RHEL7_TOOLS_URL=.*|RHEL7_TOOLS_URL=${TOOLS_RHEL7}|" sat6_configure.sh
sed -i "s|CAPSULE6_URL=.*|CAPSULE6_URL=${CAPSULE_RHEL6}|" sat6_configure.sh
sed -i "s|CAPSULE7_URL=.*|CAPSULE7_URL=${CAPSULE_RHEL7}|" sat6_configure.sh

# Set Satellite6 minor version so that right Tools and Capsule repos are created and synced.
sed -i "s|SAT_VERSION=.*|SAT_VERSION=${SATELLITE_VERSION}|" sat6_configure.sh

scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no sat6_configure.sh root@${SERVER_HOSTNAME}:/root/
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${SERVER_HOSTNAME} /root/sat6_configure.sh
