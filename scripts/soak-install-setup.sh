source ${CONFIG_FILES}

source config/provision_soak_setup.conf
source config/install_soak_setup.conf

wget -O conf/satperf.local.yaml ${SAT6_VARS_FILE}
wget -O conf/manifest.zip ${MANIFEST_LOCATION_URL}
wget -O conf/sat6.repo ${SAT6_REPO_FILE}
wget -O conf/capsule.repo ${CAPSULE_REPO_FILE}
rm -f conf/id_rsa_soak
wget -O conf/id_rsa_soak ${SSH_PRIVATE_KEY}
wget -O conf/id_rsa_soak.pub ${SSH_PUBLIC_KEY}

chmod 400 conf/id_rsa_soak

sed -i "s|sat_version:.*|sat_version: \"${SATELLITE_VERSION}\"|" conf/satperf.local.yaml
sed -i "s|content_sattools_url:.*|content_sattools_url: ${SATTOOLS_URL}|" conf/satperf.local.yaml

if [ "${SATELLITE_DISTRIBUTION}" != 'GA' ]; then
    SATELLITE_DISTRIBUTION="repo"
else
    SATELLITE_DISTRIBUTION="cdn"
fi

sed -i "s|sat_install_source:.*|sat_install_source: ${SATELLITE_DISTRIBUTION}|" conf/satperf.local.yaml
sed -i "s|capsule_install_source:.*|capsule_install_source: ${SATELLITE_DISTRIBUTION}|" conf/satperf.local.yaml


sed -i "s|satellite.example.com ip=172.17.53.1|${SATELLITE_SERVER_HOSTNAME} ip=${SATELLITE_IPADDR}|" conf/hosts.ini
sed -i "s|capsule.example.com ip=172.17.51.1|${CAPSULE_SERVER_HOSTNAME} ip=${CAPSULE_IPADDR}|" conf/hosts.ini
sed -i "s|docker.example.com ip=172.17.52.1|${DOCKER_SERVER_HOSTNAME} ip=${DOCKER_SERVER_IPADDR} docker_host_10gnic=ens1 containers=${DOCKER_HOST_COUNT} docker_host_cidr_range=22 tests_registration_target=${SATELLITE_SERVER_HOSTNAME}|" conf/hosts.ini
