if [[ "${SATELLITE_DISTRIBUTION}" != *"UPSTREAM"* ]]; then
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
fi
