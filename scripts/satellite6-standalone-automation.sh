set -o nounset

source ${CONFIG_FILES}
source config/sat6_repos_urls.conf

# https://github.com/SatelliteQE/robottelo-ci/issues/1873
pip install -U 'pip<21.0'
pip install -U --use-deprecated=legacy-resolver -r requirements.txt

if [ -n "${ROBOTTELO_PROPERTIES:-}" ]; then
    echo "${ROBOTTELO_PROPERTIES}" > ./robottelo.properties
else
    cp config/robottelo.properties ./robottelo.properties
    cp config/virtwho.properties ./virtwho.properties
    cp config/broker_settings.yaml ./broker_settings.yaml

    sed -i "s/{server_hostname}/${SERVER_HOSTNAME}/" robottelo.properties
    sed -i "s/^ssh_username.*/ssh_username=${SSH_USER}/" robottelo.properties

    sed -i "s/^admin_username.*/admin_username=${FOREMAN_ADMIN_USER}/" robottelo.properties
    sed -i "s/^admin_password.*/admin_password=${FOREMAN_ADMIN_PASSWORD}/" robottelo.properties

    sed -i "/^\[bugzilla\]/,/^\[/s/^#\?api_key=\w*/api_key=${BUGZILLA_KEY}/" robottelo.properties

    sed -i "s|sattools_repo.*|sattools_repo=rhel8=${RHEL8_TOOLS_REPO:-${TOOLS_RHEL8}},rhel7=${RHEL7_TOOLS_REPO:-${TOOLS_RHEL7}},rhel6=${RHEL6_TOOLS_REPO:-${TOOLS_RHEL6}}|" robottelo.properties
    sed -i "s|capsule_repo.*|capsule_repo=${CAPSULE_REPO}|" robottelo.properties
fi

if [ -n "${ROBOTTELO_YAML:-}" ]; then
    echo "${ROBOTTELO_YAML}" > ./robottelo.yaml
else
    cp config/robottelo.yaml ./robottelo.yaml
fi

# Sauce Labs Configuration and pytest-env setting
BROWSER="chrome"
pip install -U pytest-env
env =
   PYTHONHASHSEED=0

if [[ "${UI_PLATFORM}" != "zalenium" ]]; then
    echo "The Sauce Tunnel Identifier for Server Hostname ${SERVER_HOSTNAME} is ${TUNNEL_IDENTIFIER}"
    sed -i "s/^browser=.*/browser=saucelabs/" robottelo.properties
    sed -i "s/^# saucelabs_user=.*/saucelabs_user=${SAUCELABS_USER}/" robottelo.properties
    sed -i "s/^# saucelabs_key=.*/saucelabs_key=${SAUCELABS_KEY}/" robottelo.properties
    sed -i "s/^# webdriver=.*/webdriver=${BROWSER}/" robottelo.properties
    if [[ "${BROWSER}" == "firefox" ]]; then
        BROWSER_VERSION=47.0
    elif [[ "${BROWSER}" == "edge" ]]; then
        BROWSER_VERSION=14.14393
    elif [[ "${BROWSER}" == "chrome" ]]; then
        BROWSER_VERSION=63.0
    # Only chrome version testing support
    elif [[ -n "${BROWSER_VERSION}" ]]; then
        BROWSER_VERSION=${BROWSER_VERSION}
    fi
    if [[ -n "${SELENIUM_VERSION}" ]]; then
        SELENIUM_VERSION=${SELENIUM_VERSION}
    else
        SELENIUM_VERSION=3.141.0
    fi
    sed -i "s/^# webdriver_desired_capabilities=.*/webdriver_desired_capabilities=platform=${UI_PLATFORM},version=${BROWSER_VERSION},maxDuration=5400,idleTimeout=1000,seleniumVersion=${SELENIUM_VERSION},build=${SATELLITE_VERSION}-$(date +%Y-%m-%d-%S),screenResolution=1600x1200,extendedDebugging=true,tunnelIdentifier=${TUNNEL_IDENTIFIER}/" robottelo.properties
fi

pytest() {
    $(which py.test) -v --junit-xml=foreman-results.xml -o junit_suite_name=standalone-automation -m "${PYTEST_MARKS}" "$@"
}

if [ -n "${PYTEST_OPTIONS:-}" ]; then
    pytest ${PYTEST_OPTIONS}
else
    case "${TEST_TYPE}" in
        api|cli|ui|rhai|tier1|tier2|tier3|sys|upgrade )
            make "test-foreman-${TEST_TYPE}" PYTEST_XDIST_NUMPROCESSES="${ROBOTTELO_WORKERS}"
            ;;
        endtoend-api|endtoend-cli|endtoend-ui )
            TEST_TYPE="$(echo ${TEST_TYPE} | cut -d- -f2)"
            pytest "tests/foreman/endtoend/test_${TEST_TYPE}_endtoend.py"
            ;;
        all )
            pytest tests/foreman/api tests/foreman/cli tests/foreman/ui
            ;;
        endtoend-all )
            make test-foreman-endtoend
            ;;
        * )
            echo "TEST_TYPE=\"${TEST_TYPE}\" not found."
            exit 1
            ;;
    esac
fi
