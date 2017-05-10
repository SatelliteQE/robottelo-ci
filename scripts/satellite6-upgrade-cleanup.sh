# Setting Prerequisites
pip install -r requirements.txt

# Sourcing and exporting required env vars
source ${CONFIG_FILES}
source config/sat6_upgrade.conf

fab -H $DOCKER_VM -u root docker_cleanup_containers
