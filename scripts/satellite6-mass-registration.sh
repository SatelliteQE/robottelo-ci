echo "Sourcing config files for cdn registration.."
source ${CONFIG_FILES}
source config/subscription_config.conf

echo "Setting up Container Host"
if [ "${SETUP_CONTAINER_HOST}" == "true" ]; then
    cd playbooks
    # Note that the following playbook is temporarily hardcoded to generate rhel74 image.
    ansible-playbook --inventory=${CONTAINER_HOST}, --extra-vars "RHN_USERNAME=${RHN_USERNAME} RHN_PASSWORD=${RHN_PASSWORD} RHN_POOLID=${RHN_POOLID} WORKSPACE=${WORKSPACE} CUSTOM_CONTAINER_STARTUP_FILE=${CUSTOM_CONTAINER_STARTUP_FILE} CONTAINER_OS=${CONTAINER_OS}" chd-setup.yaml
fi

echo "Run the command for the container hosts registration"
CONTAINER_TAG=$(echo "$CONTAINER_OS" | tr '[:upper:]' '[:lower:]')
cd ${WORKSPACE}/playbooks
ansible-playbook --inventory=${CONTAINER_HOST}, --extra-vars "SATELLITE_HOST=${SATELLITE_HOST} CONTENT_HOST_PREFIX=${CONTENT_HOST_PREFIX} ACTIVATION_KEY=${ACTIVATION_KEY} NUMBER_OF_HOSTS=${NUMBER_OF_HOSTS} LIMIT=${LIMIT} EXIT_CRITERIA=${EXIT_CRITERIA} CONTAINER_TAG=${CONTAINER_TAG}" chd-run.yaml
