pip install -U pip

if [ "$(curl --version | grep NSS 2>/dev/null)" ]; then
    pip install --compile --install-option="--with-nss" pycurl
else
    pip install --compile --install-option="--with-openssl" pycurl
fi

pip install -r requirements.txt

source ${FAKE_CERT_CONFIG}
source ${INSTALL_CONFIG}
source ${PROVISIONING_CONFIG}
source ${PROXY_CONFIG}

if [ "${STAGE_TEST}" = 'false' ]; then
    source ${SUBSCRIPTION_CONFIG}
else
    source ${STAGE_CONFIG}
fi
if [ "${DISTRIBUTION}" = 'satellite6-zstream' ]; then
    DISTRIBUTION='satellite6-downstream'
fi

fab -H "root@${PROVISIONING_HOST}" "product_install:${DISTRIBUTION},create_vm=true,sat_cdn_version=${SATELLITE_VERSION},test_in_stage=${STAGE_TEST}"

SERVER_HOSTNAME="${TARGET_IMAGE}.${VM_DOMAIN}"

# Write a properties file to allow passing variables to other build steps
echo "SERVER_HOSTNAME=${SERVER_HOSTNAME}" > build_env.properties
echo "TOOLS_REPO=${TOOLS_URL}" >> build_env.properties
echo "SUBNET=${SUBNET}" >> build_env.properties
echo "NETMASK=${NETMASK}" >> build_env.properties
echo "GATEWAY=${GATEWAY}" >> build_env.properties
echo "BRIDGE=${BRIDGE}" >> build_env.properties
echo "DISCOVERY_ISO=${DISCOVERY_ISO}" >> build_env.properties

echo
echo "========================================"
echo "Server information"
echo "========================================"
echo "Hostname: ${SERVER_HOSTNAME}"
echo "Credentials: admin/changeme"
echo "========================================"
