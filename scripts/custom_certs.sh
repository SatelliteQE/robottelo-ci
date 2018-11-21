pip install -U -r requirements.txt

# To do
export DISTRO="rhel7"

source ${CONFIG_FILES}
source config/auth_servers.conf
source config/installation_environment.conf
source config/proxy_config_environment.conf
# OS_VERSION needs to be defined before sourcing sat6_repos_urls.conf
source config/sat6_repos_urls.conf
source config/client-automation.conf
source config/subscription_config.conf

# Assign DISTRIBUTION to trigger things appropriately from automation-tools.
if [ "${SATELLITE_INSTALL_DISTRIBUTION}" = 'INTERNAL' ]; then
    export DISTRIBUTION="satellite6-downstream"
elif [ "${SATELLITE_INSTALL_DISTRIBUTION}" = 'GA' ]; then
    export DISTRIBUTION="satellite6-cdn"
elif [ "${SATELLITE_INSTALL_DISTRIBUTION}" = 'INTERNAL REPOFILE' ]; then
    export DISTRIBUTION="satellite6-repofile"
elif [ "${SATELLITE_INSTALL_DISTRIBUTION}" = 'INTERNAL AK' ]; then
    export DISTRIBUTION="satellite6-activationkey"
elif [ "${SATELLITE_INSTALL_DISTRIBUTION}" = 'BETA' ]; then
    export DISTRIBUTION="satellite6-beta"
fi

# This is only used for downstream builds
if [ "${SATELLITE_INSTALL_DISTRIBUTION}" = "INTERNAL" ]; then
    # If user provided custom baseurl, use it otherwise use the default
    if [ ! -z "$SATELLITE6_CUSTOM_BASEURL" ]; then
        export BASE_URL="${SATELLITE6_CUSTOM_BASEURL}"
    else
        export BASE_URL="${SATELLITE6_REPO}"
    fi
fi

if [ -z "${SERVER_HOSTNAME}" ]; then
    set +e
    fab -D -H "root@${PROVISIONING_HOST}" "vm_destroy:target_image=${TARGET_IMAGE},delete_image=true"
    set -e
    fab -D -H "root@${PROVISIONING_HOST}" "vm_create"
    export SERVER_HOSTNAME="${TARGET_IMAGE}.${VM_DOMAIN}"
fi

# installer options for custom certs install
if [ "${SATELLITE_VERSION}" != "6.2" ] || [ "${SATELLITE_VERSION}" != "6.3" ] ; then
    export INSTALLER_OPTIONS="certs-server-cert /root/ownca/${SERVER_HOSTNAME}/${SERVER_HOSTNAME}.crt --certs-server-key /root/ownca/${SERVER_HOSTNAME}/${SERVER_HOSTNAME}.key --certs-server-ca-cert /root/ownca/${SERVER_HOSTNAME}/cacert.crt"
else
    export INSTALLER_OPTIONS="certs-server-cert /root/ownca/${SERVER_HOSTNAME}/${SERVER_HOSTNAME}.crt --certs-server-cert-req "/root/ownca/${SERVER_HOSTNAME}/${SERVER_HOSTNAME}.crt.req" --certs-server-key /root/ownca/${SERVER_HOSTNAME}/${SERVER_HOSTNAME}.key --certs-server-ca-cert /root/ownca/${SERVER_HOSTNAME}/cacert.crt"
fi

echo
echo "========================================"
echo "Server information"
echo "========================================"
echo "Hostname: ${SERVER_HOSTNAME}"
echo "========================================"

fab -D -H "root@${SERVER_HOSTNAME}" partition_disk

fab -D -H "root@${SERVER_HOSTNAME}" "generate_custom_certs"
unset TARGET_IMAGE

if [ "${ACTION}" != "CUSTOM_CERTS" ]; then
    # install satellite
    fab -D -H "root@${SERVER_HOSTNAME}" "product_install:${DISTRIBUTION},create_vm=False,sat_version=${SATELLITE_VERSION},puppet4=${PUPPET4}"
fi

if [ "${ACTION}" = "CUSTOM_CERTS" ]; then
    # update certs of existing satellite
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@"${SERVER_HOSTNAME}" "satellite-installer --scenario satellite --${INSTALLER_OPTIONS} --certs-update-server --certs-update-server-ca"
fi

# upgrade satellite
if [ "${ACTION}" = "UPGRADE" ]; then
    # source variables required for upgrade
    export FROM_VERSION=${SATELLITE_VERSION}
    export TO_VERSION=${UPGRADE_TO_VERSION}
    export SATELLITE_HOSTNAME=${SERVER_HOSTNAME}
    export SATELLITE_VERSION="${TO_VERSION}"
    source config/sat6_repos_urls.conf
    source config/subscription_config.conf
    export DISTRIBUTION=${SATELLITE_UPGRADE_DISTRIBUTION}
    if [ "${DISTRIBUTION}" = 'DOWNSTREAM' ]; then
        export BASE_URL="${SATELLITE6_REPO}"
    fi

    # Run satellite upgrade only when PERFORM_FOREMAN_MAINTAIN_UPGRADE flag is set
    if [ "${PERFORM_FOREMAN_MAINTAIN_UPGRADE}" == "true" ]; then
        # setup foreman-maintain
        fab -H root@"${SATELLITE_HOSTNAME}" setup_foreman_maintain
        # perform upgrade using foreman-maintain
        fab -H root@"${SATELLITE_HOSTNAME}" upgrade_using_foreman_maintain
    else
        fab -u root product_upgrade:"${UPGRADE_PRODUCT}"
    fi
fi
