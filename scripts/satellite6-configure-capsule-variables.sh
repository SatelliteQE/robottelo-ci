echo
echo "============================================="
echo "Populating template to configure Satellite6 "
echo "============================================="
echo


# Populates the HTTP Server information.
sed -i "s|ADMIN_PASSWORD=.*|ADMIN_PASSWORD=\"${ADMIN_PASSWORD}\"|" satellite6-populate-capsule.sh

# TODO Populates the DOWNLOAD_POLICY setting for Capsule. Future support.
# sed -i "s|DOWNLOAD_POLICY=.*|DOWNLOAD_POLICY=\"${DOWNLOAD_POLICY}\"|" satellite6-populate-capsule.sh

# Populate the Subnet Information.
# If BRIDGE is Not specified then assume it is Nested-Virt and configure foreman as the network.
# Note: foreman network is already configured via satellite6-installer Job, using the below command,
# "puppet module install -i /tmp sat6qe/katellovirt"
if [ -z "${BRIDGE}" ]; then
    export BRIDGE="foreman"
fi
sed -i "s|SUBNET_NAME=.*|SUBNET_NAME=\"${BRIDGE}\"|" satellite6-populate-capsule.sh
sed -i "s|SUBNET_RANGE=.*|SUBNET_RANGE=\"${SUBNET_RANGE}\"|" satellite6-populate-capsule.sh
sed -i "s|SUBNET_MASK=.*|SUBNET_MASK=\"${SUBNET_MASK}\"|" satellite6-populate-capsule.sh
sed -i "s|SUBNET_GATEWAY=.*|SUBNET_GATEWAY=\"${SUBNET_GATEWAY}\"|" satellite6-populate-capsule.sh

# Set Satellite6 Version, So that MEDIUM-ID is used accordingly. Note, Sat6.3 may not use MEDIUM.
sed -i "s|SAT_VERSION=.*|SAT_VERSION=\"${SATELLITE_VERSION}\"|" satellite6-populate-capsule.sh

# Set the Capsule Hostname appropriately.
sed -i "s|CAPSULE_HOSTNAME=.*|CAPSULE_HOSTNAME=\"${CAPSULE_FQDN}\"|" satellite6-populate-capsule.sh

scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no satellite6-populate-capsule.sh root@"${SATELLITE_SERVER_HOSTNAME}":/root/

ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@"${SATELLITE_SERVER_HOSTNAME}" /root/satellite6-populate-capsule.sh
