#Setting up required Variables for populating the Sat6 Repos needed by config/sat6_repos_urls.conf file.
export OS
export SATELLITE_VERSION
# Specify DISTRO as subscription_config file requires it.
export DISTRO="${OS}"
export OS_VERSION="${OS: -1}"
export TO_VERSION="${SATELLITE_VERSION}"

# FROM_VERSION calculation according to trigger type
if [ "${ZSTREAM_UPGRADE}" = 'true' ]; then
    export FROM_VERSION="${TO_VERSION}"
else
    export FROM_VERSION=$(echo ${SATELLITE_VERSION} - 0.1 | bc)
fi

# Export BZ credentials to skip the tests with BZ
# This will be used robozilla's pytest_skip_if_bug_open decorator
export BUGZILLA_ENVIRON_USER_NAME="${BUGZILLA_USER}"
export BUGZILLA_ENVIRON_USER_PASSWORD_NAME="${BUGZILLA_PASSWORD}"
export BUGZILLA_ENVIRON_SAT_VERSION="${TO_VERSION}"
