echo
echo "============================================="
echo "Populating template to configure Satellite6 "
echo "============================================="
echo


# Populates the HTTP Server information.
sed -i "s|ADMIN_PASSWORD=.*|ADMIN_PASSWORD=\"${ADMIN_PASSWORD}\"|" satellite6-populate.sh

# Populates the HTTP Server information.
sed -i "s|MANIFEST_LOCATION_URL=.*|MANIFEST_LOCATION_URL=\"${MANIFEST_LOCATION_URL}\"|" satellite6-populate.sh

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

# Populate the VMware CR information.
sed -i "s|VMWARE_URL=.*|VMWARE_URL=\"${VMWARE_URL}\"|" satellite6-populate.sh
sed -i "s|VMWARE_USERNAME=.*|VMWARE_USERNAME=\"${VMWARE_USERNAME}\"|" satellite6-populate.sh
sed -i "s|VMWARE_PASSWORD=.*|VMWARE_PASSWORD=\"${VMWARE_PASSWORD}\"|" satellite6-populate.sh
sed -i "s|VMWARE_DATACENTER=.*|VMWARE_DATACENTER=\"${VMWARE_DATACENTER}\"|" satellite6-populate.sh

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
sed -i "s|MAINTAIN7_URL=.*|MAINTAIN7_URL=\"${MAINTAIN_REPO}\"|" satellite6-populate.sh

# Set Satellite6 Version, So that MEDIUM-ID is used accordingly. Note, Sat6.3 may not use MEDIUM.
sed -i "s|SAT_VERSION=.*|SAT_VERSION=\"${SATELLITE_VERSION}\"|" satellite6-populate.sh

# By default RHEL 6Server-x86_64 and RHEL 7Server-x86_64 content only is planned to be synced.
# This shall be called as minimal install and by default it would sync only these content.
sed -i "s|MINIMAL_INSTALL=.*|MINIMAL_INSTALL=\"${MINIMAL_INSTALL}\"|" satellite6-populate.sh

if [[ -n "${POPULATE_CLIENTS_ARCH}" ]]; then
    sed -i "s|POPULATE_CLIENTS_ARCH=.*|POPULATE_CLIENTS_ARCH=\"${POPULATE_CLIENTS_ARCH}\"|" satellite6-populate.sh
    sed -i "s|RHEL6_TOOLS_PPC64_URL=.*|RHEL6_TOOLS_PPC64_URL=\"${TOOLS_RHEL6_PPC64}\"|" satellite6-populate.sh
    sed -i "s|RHEL7_TOOLS_PPC64_URL=.*|RHEL7_TOOLS_PPC64_URL=\"${TOOLS_RHEL7_PPC64}\"|" satellite6-populate.sh
    sed -i "s|RHEL6_TOOLS_S390X_URL=.*|RHEL6_TOOLS_S390X_URL=\"${TOOLS_RHEL6_S390X}\"|" satellite6-populate.sh
    sed -i "s|RHEL7_TOOLS_S390X_URL=.*|RHEL7_TOOLS_S390X_URL=\"${TOOLS_RHEL7_S390X}\"|" satellite6-populate.sh
    sed -i "s|RHEL6_TOOLS_I386_URL=.*|RHEL6_TOOLS_I386_URL=\"${TOOLS_RHEL6_I386}\"|" satellite6-populate.sh
    sed -i "s|RHEL5_TOOLS_URL=.*|RHEL5_TOOLS_URL=\"${TOOLS_RHEL5}\"|" satellite6-populate.sh
    sed -i "s|RHEL5_TOOLS_PPC64_URL=.*|RHEL5_TOOLS_PPC64_URL=\"${TOOLS_RHEL5_PPC64}\"|" satellite6-populate.sh
    sed -i "s|RHEL5_TOOLS_S390X_URL=.*|RHEL5_TOOLS_S390X_URL=\"${TOOLS_RHEL5_S390X}\"|" satellite6-populate.sh
    sed -i "s|RHEL5_TOOLS_IA64_URL=.*|RHEL5_TOOLS_IA64_URL=\"${TOOLS_RHEL5_IA64}\"|" satellite6-populate.sh
    sed -i "s|RHEL5_TOOLS_I386_URL=.*|RHEL5_TOOLS_I386_URL=\"${TOOLS_RHEL5_I386}\"|" satellite6-populate.sh
fi
if [[ -n "${POPULATE_RHEL5}" ]]; then
    sed -i "s|POPULATE_RHEL5=.*|POPULATE_RHEL5=\"${POPULATE_RHEL5}\"|" satellite6-populate.sh
fi
if [[ -n "${POPULATE_RHEL6}" ]]; then
    sed -i "s|POPULATE_RHEL6=.*|POPULATE_RHEL6=\"${POPULATE_RHEL6}\"|" satellite6-populate.sh
fi

if [[ "${RERUN}" != 'true' ]]; then
    scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no satellite6-populate.sh root@"${SERVER_HOSTNAME}":/root/
fi

# This will only populate the template with all values and transfer the template to the mentioned SERVER_HOSTNAME.
# Required when we need to further customize things on the fly.
if [[ "${ONLY_POPULATE_TEMPLATE}" = 'true' ]]; then
    sed -i "s|ONLY_POPULATE_TEMPLATE=.*|ONLY_POPULATE_TEMPLATE=\"${ONLY_POPULATE_TEMPLATE}\"|" satellite6-populate.sh
else
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@"${SERVER_HOSTNAME}" /root/satellite6-populate.sh
fi
