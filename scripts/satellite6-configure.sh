pip install -r requirements.txt

source ${CONFIG_FILES}
source config/installation_environment.conf
source config/sat6_repos_urls.conf
if [ "${DEFAULT_COMPUTE_RESOURCES}" = 'true' ]; then
    source config/compute_resources.conf
else
    LIBVIRT_URL="qemu+ssh://root@${LIBVIRT_HOSTNAME}/system"
    RHEV_URL="https://${RHEV_HOSTNAME}:443/api"
    OS_URL="http://${OSP_HOSTNAME}:5000/v2.0/tokens"
fi

if [ "${SATELLITE_DISTRIBUTION}" = 'INTERNAL' ]; then
    export SATELLITE_DISTRIBUTION="INTERNAL"
elif [ "${SATELLITE_DISTRIBUTION}" = 'INTERNAL REPOFILE' ]; then
    export SATELLITE_DISTRIBUTION="INTERNAL"
elif [ "${SATELLITE_DISTRIBUTION}" = 'INTERNAL AK' ]; then
    export SATELLITE_DISTRIBUTION="INTERNAL"
fi


if [[ -n "${POPULATE_CLIENTS_ARCH}" ]]; then
    wget https://raw.githubusercontent.com/SatelliteQE/robottelo-ci/master/scripts/satellite6-populate-template.sh
    wget https://raw.githubusercontent.com/SatelliteQE/robottelo-ci/master/scripts/satellite6-client-arch-template.sh
    cp satellite6-populate-template.sh satellite6-populate.sh
    chmod 755 satellite6-populate.sh
    cat satellite6-client-arch-template.sh >> satellite6-populate.sh
else
    cp ${PWD}/scripts/satellite6-populate-template.sh satellite6-populate.sh
    chmod 755 satellite6-populate.sh
fi


if [[ -n "${NMINUSONE}" ]]; then
    if [[ "${SATELLITE_VERSION}" = "6.4" ]]; then
        export SATELLITE_VERSION=6.3
    elif [[ "${SATELLITE_VERSION}" = "6.3" ]]; then
        export SATELLITE_VERSION=6.2
    fi
fi
