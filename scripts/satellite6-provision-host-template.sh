
RHEL7_LIBVIRT_HOST="rhel-7-libvirt"
RHEL6_LIBVIRT_HOST="rhel-6-libvirt"

# Provision a host with Libvirt Provider.
satellite_runner host create --name="${RHEL7_LIBVIRT_HOST}" --root-password='changeme' --organization-id="${ORG}" --location-id="${LOC}" --hostgroup="RHEL 7 Server 64-bit HG" --compute-resource="$COMPUTE_RESOURCE_NAME_LIBVIRT" --compute-attributes="cpus=1, memory=1073741824, start=1" --interface="primary=true, compute_type=bridge, compute_bridge=${SUBNET_NAME}, compute_model=virtio" --volume="capacity=10G,format_type=qcow2"

satellite_runner host create --name="${RHEL6_LIBVIRT_HOST}" --root-password='changeme' --organization-id="${ORG}" --location-id="${LOC}" --hostgroup="RHEL 6 Server 64-bit HG" --compute-resource="$COMPUTE_RESOURCE_NAME_LIBVIRT" --compute-attributes="cpus=1, memory=2073741824, start=1" --interface="primary=true, compute_type=bridge, compute_bridge=${SUBNET_NAME}, compute_model=virtio" --volume="capacity=10G,format_type=qcow2"

DOMAIN_NAME=$(satellite --csv domain list  | awk -F "," '!/Name/ {print $2}')

RHEL7_IP=$(nslookup "${RHEL7_LIBVIRT_HOST}.${DOMAIN_NAME}" localhost | awk '/Address/ {print $2}' | tail -n 1)
RHEL6_IP=$(nslookup "${RHEL6_LIBVIRT_HOST}.${DOMAIN_NAME}" localhost | awk '/Address/ {print $2}' | tail -n 1)

echo "RHEL7 hosts IP is: ${RHEL7_IP}"
echo "RHEL6 hosts IP is: ${RHEL6_IP}"

# This sleep is needed, because of the provisioning phase during this period.
sleep 1800

satellite_runner host package install --host "${RHEL7_LIBVIRT_HOST}.${DOMAIN_NAME}"  --packages zsh

satellite_runner host package install --host "${RHEL6_LIBVIRT_HOST}.${DOMAIN_NAME}"  --packages zsh

satellite_runner host delete --name "${RHEL7_LIBVIRT_HOST}.${DOMAIN_NAME}"

satellite_runner host delete --name "${RHEL6_LIBVIRT_HOST}.${DOMAIN_NAME}"
