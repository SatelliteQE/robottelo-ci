
RHEL7_LIBVIRT_HOST="rhel-7-libvirt"
RHEL6_LIBVIRT_HOST="rhel-6-libvirt"
VMWARE_HOST="rhel-7-vmware"

# Provision a host with Libvirt Provider.
satellite_runner host create --name="${RHEL7_LIBVIRT_HOST}" --root-password='changeme' --organization-id="${ORG}" --location-id="${LOC}" --hostgroup="RHEL 7 Server 64-bit HG" --compute-resource="$COMPUTE_RESOURCE_NAME_LIBVIRT" --compute-attributes="cpus=1, memory=1073741824, start=1" --interface="primary=true, compute_type=bridge, compute_bridge=${SUBNET_NAME}, compute_model=virtio" --volume="capacity=10G,format_type=qcow2"

satellite_runner host create --name="${RHEL6_LIBVIRT_HOST}" --root-password='changeme' --organization-id="${ORG}" --location-id="${LOC}" --hostgroup="RHEL 6 Server 64-bit HG" --compute-resource="$COMPUTE_RESOURCE_NAME_LIBVIRT" --compute-attributes="cpus=1, memory=2073741824, start=1" --interface="primary=true, compute_type=bridge, compute_bridge=${SUBNET_NAME}, compute_model=virtio" --volume="capacity=10G,format_type=qcow2"

DOMAIN_NAME=$(satellite --csv domain list  | awk -F "," '!/Name/ {print $2}')

RHEL7_IP=$(nslookup "${RHEL7_LIBVIRT_HOST}.${DOMAIN_NAME}" localhost | awk '/Address/ {print $2}' | tail -n 1)
RHEL6_IP=$(nslookup "${RHEL6_LIBVIRT_HOST}.${DOMAIN_NAME}" localhost | awk '/Address/ {print $2}' | tail -n 1)

echo "RHEL7 hosts IP is: ${RHEL7_IP}"
echo "RHEL6 hosts IP is: ${RHEL6_IP}"

# This sleep is needed, because of the provisioning phase during this period.
sleep 1200

#satellite_runner host package install --host "${RHEL7_LIBVIRT_HOST}.${DOMAIN_NAME}"  --packages zsh

#satellite_runner host package install --host "${RHEL6_LIBVIRT_HOST}.${DOMAIN_NAME}"  --packages zsh

satellite_runner host delete --name "${RHEL7_LIBVIRT_HOST}.${DOMAIN_NAME}"

satellite_runner host delete --name "${RHEL6_LIBVIRT_HOST}.${DOMAIN_NAME}"

# Provision a host with VMware Provider.
satellite_runner host create --name="${VMWARE_HOST}" --root-password='changeme' --domain-id "${DOMAIN_ID}" --subnet "${SUBNET_NAME}" --organization-id="${ORG}" --build true --location-id="${LOC}" --hostgroup="RHEL 7 Server 64-bit HG" --provision-method build --compute-resource="$COMPUTE_RESOURCE_NAME_VMWARE" --interface="managed=true,primary=true,provision=true,compute_type=VirtualE1000,compute_network=\"qe_${SUBNET_NAME}\"" --volume="size_gb=20G,datastore=Local-Ironforge,name=myharddisk,thin=true,eager_zero=false,mode=persistent" --compute-attributes="cpus=1,corespersocket=2,memory_mb=4096,cluster=Satellite-Engineering,path=/Datacenters/RH_Engineering/vm,start=1"

# This sleep is needed, because of the provisioning phase during this period.
sleep 1200

satellite_runner host delete --name "${VMWARE_HOST}.${DOMAIN_NAME}"
