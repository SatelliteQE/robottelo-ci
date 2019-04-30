if [[ "${SATELLITE_VERSION}" != *"nightly"* ]]; then
    source config/installation_environment.conf
    BUILD_LABEL=`echo "${BUILD_LABEL%%-*}" | sed -e "s/Satellite //"`
    export BUILD_LABEL
    pip install -r requirements.txt
    fab -D -H "root@${SERVER_HOSTNAME}" "configure_sonarqube"
fi
