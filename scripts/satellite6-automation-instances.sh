
ssh_opts='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'

function wait_for_ssh () {
    sleeps=${2:-120}
    for ((i=0; i<$sleeps; i++)); do
        nc -n "$1" 22 <<< "" 2>/dev/null && break
        sleep 1
    done
    echo "$i sleeps" 
}

function remove_instance () {
    echo "========================================"
    echo " Remove any running instances if any of ${TARGET_IMAGE} virsh domain."
    echo "========================================"
    set +e
    ssh $ssh_opts root@"${PROVISIONING_HOST}" virsh destroy ${TARGET_IMAGE}
    ssh $ssh_opts root@"${PROVISIONING_HOST}" virsh undefine ${TARGET_IMAGE}
    ssh $ssh_opts root@"${PROVISIONING_HOST}" virsh vol-delete --pool default /var/lib/libvirt/images/${TARGET_IMAGE}.img
    set -e
}

function setup_instance () {
    # Provision the instance using satellite6 base image as the source image.
    ssh $ssh_opts root@"${PROVISIONING_HOST}" \
    snap-guest -b "${SOURCE_IMAGE}" -t "${TARGET_IMAGE}" --hostname "${SERVER_HOSTNAME}" \
    -m "${VM_RAM}" -c "${VM_CPU}" -d "${VM_DOMAIN}" -f -n bridge="${BRIDGE}" --static-ipaddr "${TIER_IPADDR}" \
    --static-netmask "${NETMASK}" --static-gateway "${GATEWAY}"

    # Let's wait for the instance to be up to ssh into it
    wait_for_ssh "${TIER_IPADDR}" 120

    # Restart Satellite6 service for a clean state of the running instance.
    ssh $ssh_opts root@"${SERVER_HOSTNAME}" hostnamectl set-hostname "${TIER_SOURCE_IMAGE%%-base}.${VM_DOMAIN}"
    ssh $ssh_opts root@"${SERVER_HOSTNAME}" sed -i '/redhat.com/d' /etc/hosts
    ssh $ssh_opts root@"${SERVER_HOSTNAME}" "echo ${TIER_IPADDR} ${TIER_SOURCE_IMAGE%%-base}.${VM_DOMAIN} ${TIER_SOURCE_IMAGE%%-base} >> /etc/hosts"
    ssh $ssh_opts root@"${SERVER_HOSTNAME}" 'katello-service restart'
    sleep 40
    if [[ "${SATELLITE_VERSION}" == "6.1" ]]; then
        echo "Changing of Satellite6 Hostname is not supported for Satellite6.1, it is only supported from Sat6.2 and later."
    else
        if [[ ${SATELLITE_VERSION} =~ ^(6.2|upstream-nightly)$ ]]; then
            sleep 240
            rename_cmd="katello-change-hostname"
        else
            rename_cmd="satellite-change-hostname"
        fi
        ssh $ssh_opts root@"${SERVER_HOSTNAME}" $rename_cmd "${SERVER_HOSTNAME}" -y -u admin -p changeme
    fi

    if [[ ${ENDPOINT} =~ ^(tier1|tier2|rhai|destructive)$ ]]; then
        ssh $ssh_opts root@"${SERVER_HOSTNAME}" systemctl stop dhcpd
    fi
}

# Provisioning jobs TARGET_IMAGE becomes the SOURCE_IMAGE for Tier and RHAI jobs.
# source-image at this stage for example: qe-sat63-rhel7-base
export SOURCE_IMAGE="${TIER_SOURCE_IMAGE}"
# target-image at this stage for example: qe-sat63-rhel7-tier1
export TARGET_IMAGE="${TIER_SOURCE_IMAGE%%-base}-${ENDPOINT}"

export SERVER_HOSTNAME="${TARGET_IMAGE}.${VM_DOMAIN}"

remove_instance
setup_instance
