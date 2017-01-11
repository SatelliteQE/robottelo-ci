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

function remove_instance () {
    # For Example: The TARGET_IMAGE in provision_libvirt_install.conf should be "qe-test-rhel7".
    export TARGET_IMAGE
    export SERVER_HOSTNAME="${TARGET_IMAGE}.${VM_DOMAIN}"
    set +e
    fab -H "root@$1" "vm_destroy:target_image=${TARGET_IMAGE},delete_image=true"
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

fab -H "root@${PROVISIONING_HOST}" "product_install:${DISTRIBUTION},create_vm=true,sat_cdn_version=${SATELLITE_VERSION},test_in_stage=${STAGE_TEST}"

echo
echo "========================================"
echo "Server information"
echo "========================================"
echo "Hostname: ${SERVER_HOSTNAME}"
echo "Credentials: admin/changeme"
echo "========================================"

# Download the Satellite6 Configure Template.
wget ${HTTP_SERVER_HOSTNAME}/pub/sat6_configure_template.sh

echo
echo "============================================="
echo "Populating template to configure Satellite6 "
echo "============================================="
echo

cp sat6_configure_template.sh sat6_configure.sh
chmod 755 sat6_configure.sh

# Populate the Subnet Information
sed -i "s|SUBNET_NAME=.*|SUBNET_NAME=${BRIDGE}|" sat6_configure.sh
sed -i "s|SUBNET_RANGE=.*|SUBNET_RANGE=${SUBNET}|" sat6_configure.sh
sed -i "s|SUBNET_MASK=.*|SUBNET_MASK=${NETMASK}|" sat6_configure.sh
sed -i "s|SUBNET_GATEWAY=.*|SUBNET_GATEWAY=${GATEWAY}|" sat6_configure.sh

# Updates the REPO URLS automatically depending upon the Satellite6 Version selected in the job.
# This is done by using the already maintained sat6_repo_url config file.
sed -i "s|RHEL6_TOOLS_URL=.*|RHEL6_TOOLS_URL=${TOOLS_RHEL6}|" sat6_configure.sh
sed -i "s|RHEL7_TOOLS_URL=.*|RHEL7_TOOLS_URL=${TOOLS_RHEL7}|" sat6_configure.sh
sed -i "s|CAPSULE6_URL=.*|CAPSULE6_URL=${CAPSULE_RHEL6}|" sat6_configure.sh
sed -i "s|CAPSULE7_URL=.*|CAPSULE7_URL=${CAPSULE_RHEL7}|" sat6_configure.sh

# Set Satellite6 Version, So that MEDIUM-ID is used accordingly. Note, Sat6.3 may not use MEDIUM.
sed -i "s|SAT_VERSION=.*|SAT_VERSION=${SATELLITE_VERSION}|" sat6_configure.sh

# By default RHEL 6Server-x86_64 and RHEL 7Server-x86_64 content only is planned to be synced.
# This shall be called as minimal install and by default it would sync only these content.
sed -i "s|MINIMAL_INSTALL=.*|MINIMAL_INSTALL=${MINIMAL_INSTALL}|" sat6_configure.sh


scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no sat6_configure.sh root@${SERVER_HOSTNAME}:/root/
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${SERVER_HOSTNAME} /root/sat6_configure.sh
