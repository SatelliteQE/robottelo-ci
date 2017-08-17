echo
echo "============================================="
echo "Populating template to configure Satellite6 "
echo "============================================="
echo

# Populates the HTTP Server information.
sed -i "s|HTTP_SERVER_HOSTNAME=.*|HTTP_SERVER_HOSTNAME=\"${HTTP_SERVER_HOSTNAME}\"|" satellite6-populate.sh

# Populates the DOWNLOAD_POLICY setting.
sed -i "s|DOWNLOAD_POLICY=.*|DOWNLOAD_POLICY=\"${DOWNLOAD_POLICY}\"|" satellite6-populate.sh

# Populates the SATELLITE_DISTRIBUTION method.
sed -i "s|SATELLITE_DISTRIBUTION=.*|SATELLITE_DISTRIBUTION=\"${SATELLITE_DISTRIBUTION}\"|" satellite6-populate.sh

# Populates the Compute Resource Information.

# Populate the Libvirt CR Info
sed -i "s|LIBVIRT_URL=.*|LIBVIRT_URL=\"${LIBVIRT_URL}\"|" satellite6-populate.sh

# Populate the RHEV CR Information.
sed -i "s|RHEV_URL=.*|RHEV_URL=\"${RHEV_URL}\"|" satellite6-populate.sh
sed -i "s|RHEV_USERNAME=.*|RHEV_USERNAME=\"${RHEV_USER}\"|" satellite6-populate.sh
sed -i "s|RHEV_PASSWORD=.*|RHEV_PASSWORD=\"${RHEV_PASSWD}\"|" satellite6-populate.sh
sed -i "s|RHEV_DATACENTER_UUID=.*|RHEV_DATACENTER_UUID=\"${RHEV_DATACENTER_UUID}\"|" satellite6-populate.sh

# Populate the OSP CR Information.
sed -i "s|OS_URL=.*|OS_URL=\"${OS_URL}\"|" satellite6-populate.sh
sed -i "s|OS_USERNAME=.*|OS_USERNAME=\"${OS_USERNAME}\"|" satellite6-populate.sh
sed -i "s|OS_PASSWORD=.*|OS_PASSWORD=\"${OS_PASSWORD}\"|" satellite6-populate.sh

# Populate the Subnet Information.
# If BRIDGE is Not specified then assume it is Nested-Virt and configure foreman as the network.
# Note: foreman network is already configured via satellite6-installer Job, using the below command,
# "puppet module install -i /tmp sat6qe/katellovirt"
if [ -z "${BRIDGE}" ]; then
    export BRIDGE="foreman"
fi
sed -i "s|SUBNET_NAME=.*|SUBNET_NAME=\"${BRIDGE}\"|" satellite6-populate.sh
sed -i "s|SUBNET_RANGE=.*|SUBNET_RANGE=\"${SUBNET_RANGE}\"|" satellite6-populate.sh
sed -i "s|SUBNET_MASK=.*|SUBNET_MASK=\"${SUBNET_MASK}\"|" satellite6-populate.sh
sed -i "s|SUBNET_GATEWAY=.*|SUBNET_GATEWAY=\"${SUBNET_GATEWAY}\"|" satellite6-populate.sh

# Updates the REPO URLS automatically depending upon the Satellite6 Version selected in the job.
# This is done by using the already maintained sat6_repos_urls config file.
sed -i "s|RHEL6_TOOLS_URL=.*|RHEL6_TOOLS_URL=\"${TOOLS_RHEL6}\"|" satellite6-populate.sh
sed -i "s|RHEL7_TOOLS_URL=.*|RHEL7_TOOLS_URL=\"${TOOLS_RHEL7}\"|" satellite6-populate.sh
sed -i "s|CAPSULE6_URL=.*|CAPSULE6_URL=\"${CAPSULE_RHEL6}\"|" satellite6-populate.sh
sed -i "s|CAPSULE7_URL=.*|CAPSULE7_URL=\"${CAPSULE_RHEL7}\"|" satellite6-populate.sh

# Set Satellite6 Version, So that MEDIUM-ID is used accordingly. Note, Sat6.3 may not use MEDIUM.
sed -i "s|SAT_VERSION=.*|SAT_VERSION=\"${SATELLITE_VERSION}\"|" satellite6-populate.sh

# By default RHEL 6Server-x86_64 and RHEL 7Server-x86_64 content only is planned to be synced.
# This shall be called as minimal install and by default it would sync only these content.
sed -i "s|MINIMAL_INSTALL=.*|MINIMAL_INSTALL=\"${MINIMAL_INSTALL}\"|" satellite6-populate.sh

scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no satellite6-populate.sh root@"${SERVER_HOSTNAME}":/root/

# This will only populate the template with all values and transfer the template to the mentioned SERVER_HOSTNAME.
# Required when we need to further customize things on the fly.
if [[ "${ONLY_POPULATE_TEMPLATE}" = 'true' ]]; then
    exit 1
fi
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@"${SERVER_HOSTNAME}" /root/satellite6-populate.sh
