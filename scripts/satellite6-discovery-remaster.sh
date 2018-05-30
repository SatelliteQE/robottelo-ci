pip install -r requirements.txt
source ${CONFIG_FILES}
source config/provisioning_env_with_endpoints.conf
source config/compute_resources.conf
source config/sat6_repos_urls.conf

export BASE_URL=${SATELLITE6_REPO}
export IPADDR=${TIER_IPADDR}

fab -D -H "root@${LIBVIRT_HOSTNAME}" get_discovery_image
