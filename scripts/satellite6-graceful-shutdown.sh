ssh_opts='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'

echo "Shutting down the Base instance of ${SERVER_HOSTNAME} gracefully"
# Shutdown the Satellite6 services before shutdown.
ssh $ssh_opts root@"${SERVER_HOSTNAME}" katello-service stop
# Try to shutdown the Satellite6 instance gracefully and sleep for a while.
ssh $ssh_opts root@"${PROVISIONING_HOST}" virsh shutdown ${TARGET_IMAGE}
sleep 120
set +e
# Destroy the sat6 instance anyways if for some reason virsh shutdown couldn't gracefully shut it down.
ssh $ssh_opts root@"${PROVISIONING_HOST}" virsh destroy ${TARGET_IMAGE}
set -e
echo "========================================"
