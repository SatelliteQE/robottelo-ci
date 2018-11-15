set -o nounset

source ${CONFIG_FILES}
source config/sat6_repos_urls.conf

pip install -U -r requirements.txt docker-py pytest-xdist sauceclient

if [ -n "${ROBOTTELO_PROPERTIES:-}" ]; then
    echo "${ROBOTTELO_PROPERTIES}" > ./robottelo.properties
else
    cp config/robottelo.properties ./robottelo.properties

    sed -i "s/{server_hostname}/${SERVER_HOSTNAME}/" robottelo.properties
    sed -i "s/^ssh_username.*/ssh_username=${SSH_USER}/" robottelo.properties

    sed -i "s/^admin_username.*/admin_username=${FOREMAN_ADMIN_USER}/" robottelo.properties
    sed -i "s/^admin_password.*/admin_password=${FOREMAN_ADMIN_PASSWORD}/" robottelo.properties

    sed -i "s/# bz_password=.*/bz_password=${BUGZILLA_PASSWORD}/" robottelo.properties
    sed -i "s/# bz_username=.*/bz_username=${BUGZILLA_USER}/" robottelo.properties

    sed -i "s|sattools_repo.*|sattools_repo=rhel7=${RHEL7_TOOLS_REPO:-${TOOLS_RHEL7}},rhel6=${RHEL6_TOOLS_REPO:-${TOOLS_RHEL6}}|" robottelo.properties
    sed -i "s|capsule_repo.*|capsule_repo=${CAPSULE_REPO}|" robottelo.properties
fi

if [-n "${ROBOTTELO_YAML:-}" ]; then
    echo "${ROBOTTELO_YAML}" > ./robottelo.yaml
else
    cp config/robottelo.yaml ./robottelo.yaml
fi

# Sauce Labs Configuration and pytest-env setting
if [[ "${SATELLITE_VERSION}" == "6.4" || "${SATELLITE_VERSION}" == "6.5" ]]; then
    SAUCE_BROWSER="chrome"

    pip install -U pytest-env

    env =
        PYTHONHASHSEED=0
fi


if [[ "${SAUCE_PLATFORM}" != "no_saucelabs" ]]; then
    echo "The Sauce Tunnel Identifier for Server Hostname ${SERVER_HOSTNAME} is ${TUNNEL_IDENTIFIER}"
    sed -i "s/^browser=.*/browser=saucelabs/" robottelo.properties
    sed -i "s/^# saucelabs_user=.*/saucelabs_user=${SAUCELABS_USER}/" robottelo.properties
    sed -i "s/^# saucelabs_key=.*/saucelabs_key=${SAUCELABS_KEY}/" robottelo.properties
    sed -i "s/^# webdriver=.*/webdriver=${SAUCE_BROWSER}/" robottelo.properties
    if [[ "${SAUCE_BROWSER}" == "firefox" ]]; then
        if [[ "${SATELLITE_VERSION}" == "6.1" ]]; then
            BROWSER_VERSION=45.0
        else
            BROWSER_VERSION=47.0
        fi
    elif [[ "${SAUCE_BROWSER}" == "edge" ]]; then
        BROWSER_VERSION=14.14393
    elif [[ "${SAUCE_BROWSER}" == "chrome" ]]; then
        BROWSER_VERSION=63.0
    fi
    if [[ "${SATELLITE_VERSION}" == "6.1" ]]; then
        SELENIUM_VERSION=2.48.0
    elif [[ "${SATELLITE_VERSION}" == "6.2" || "${SATELLITE_VERSION}" == "6.3" ]]; then
        SELENIUM_VERSION=2.53.1
    else
        SELENIUM_VERSION=3.8.1
    fi
    sed -i "s/^# webdriver_desired_capabilities=.*/webdriver_desired_capabilities=platform=${SAUCE_PLATFORM},version=${BROWSER_VERSION},maxDuration=5400,idleTimeout=1000,seleniumVersion=${SELENIUM_VERSION},build=${SATELLITE_VERSION}-$(date +%Y-%m-%d-%S),screenResolution=1600x1200,tunnelIdentifier=${TUNNEL_IDENTIFIER}/" robottelo.properties
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
