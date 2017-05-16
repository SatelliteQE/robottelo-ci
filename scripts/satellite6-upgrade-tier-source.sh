 # Sourcing and exporting required env vars for tier jobs
source ${CONFIG_FILES}
source config/compute_resources.conf
source config/sat6_upgrade.conf
export SERVER_HOSTNAME="${SERVER_HOSTNAME:-${RHEV_SAT_HOST}}"
