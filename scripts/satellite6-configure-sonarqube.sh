if [[ "${DISTRO}" != "rhel6" ]]; then
    if [[ "${SATELLITE_VERSION}" != *"nightly"* ]] && [[ "${SATELLITE_VERSION}" != "6.1" ]]; then
        source config/installation_environment.conf
        export BUILD_LABEL
        fab -H "root@${SERVER_HOSTNAME}" "configure_sonarqube"
    fi
fi
