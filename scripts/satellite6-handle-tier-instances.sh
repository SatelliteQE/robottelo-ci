source ${CONFIG_FILES}
source config/provisioning_environment.conf
export TARGET_BASE_IMAGE="${TARGET_IMAGE}"
export TARGET_IMAGE="${TARGET_IMAGE%%-base}-${ENDPOINT}"
if [ "${ACTION}" = "start" ]; then
    echo "========================================"
    echo " Start the instances of ${TARGET_IMAGE} virsh domain."
    echo "========================================"
    set +e
    ping -c 1 ${IPADDR}
    RESULT=$?
    if [ $RESULT -eq 1 ]; then
        ssh -o StrictHostKeyChecking=no root@"${PROVISIONING_HOST}" virsh start ${TARGET_IMAGE}
        set -e
        sleep 60
        ssh -o StrictHostKeyChecking=no root@"${TARGET_BASE_IMAGE%%-base}.${VM_DOMAIN}" katello-service restart
    elif [ $RESULT -eq 0 ]; then
        echo "An instance with IP: ${IPADDR} is already running and so cannot start this instance."
        echo "Shutdown other instances using the IP: ${IPADDR} and then start this instance."
        echo "Below could be one of the running instances on this ${PROVISIONING_HOST}"
        set +e
        ssh -o StrictHostKeyChecking=no root@"${PROVISIONING_HOST}" virsh list | grep ${TARGET_BASE_IMAGE%%-base}
        set -e
        echo "Also check for other running instances at rhevm1 or on other Compute Resources."
    fi
elif [ "${ACTION}" = "destroy" ]; then
    echo "========================================"
    echo " Destroy the instances of ${TARGET_IMAGE} virsh domain."
    echo "========================================"
    ssh -o StrictHostKeyChecking=no root@"${TARGET_BASE_IMAGE%%-base}.${VM_DOMAIN}" katello-service stop
    set +e
    # Gracefully shutdown the vm instance.
    ssh -o StrictHostKeyChecking=no root@"${PROVISIONING_HOST}" virsh shutdown ${TARGET_IMAGE}
    sleep 60
    ssh -o StrictHostKeyChecking=no root@"${PROVISIONING_HOST}" virsh destroy ${TARGET_IMAGE}
    set -e
fi
