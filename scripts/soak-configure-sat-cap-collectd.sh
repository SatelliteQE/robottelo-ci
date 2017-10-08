source ${CONFIG_FILES}

source config/configure_soak_collectd.conf

wget -O conf/satmon.yaml ${SAT6_MON_VARS_FILE}
wget -O conf/id_rsa_soak ${SSH_PRIVATE_KEY}
wget -O conf/id_rsa_soak.pub ${SSH_PUBLIC_KEY}

chmod 400 conf/id_rsa_soak

cp conf/hosts.ini.sample conf/hosts.ini

if [ "${SATELLITE_VERSION}" = '6.3' ]; then
    export GRAPHITE_PREFIX=satellite63
elif [ "${SATELLITE_VERSION}" = '6.2' ]; then
    export GRAPHITE_PREFIX=satellite62
fi

sed -i "s|satellite.example.com|${SATELLITE_SERVER_HOSTNAME}|" conf/hosts.ini
sed -i "s|#capsule1.example.com|${CAPSULE_SERVER_HOSTNAME}|" conf/hosts.ini

sed -i "s|#graphite.example.com|${CARBON_SERVER_HOSTNAME}|" conf/hosts.ini
sed -i "s|#grafana.example.com|${GRAFANA_SERVER_HOSTNAME}|" conf/hosts.ini

sed -i "s|graphite_prefix:.*|graphite_prefix: ${GRAPHITE_PREFIX}|" conf/satmon.yaml

ansible-playbook --private-key conf/id_rsa_soak -i conf/hosts.ini ansible/collectd-generic.yaml --tags "satellite6"

ansible-playbook --private-key conf/id_rsa_soak -i conf/hosts.ini ansible/collectd-generic.yaml --tags "capsules"
