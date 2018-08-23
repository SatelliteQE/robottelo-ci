source ${CONFIG_FILES}
source config/sat6_repos_urls.conf

pip install -U -r requirements.txt
cp testfm/inventory.sample testfm/inventory

if [ "${COMPONENT}" == "capsule" ]; then
    sed -i "s/<capsule_hostname>/${SERVER_HOSTNAME}/g" testfm/inventory
else
    sed -i "s/<server_hostname>/${SERVER_HOSTNAME}/g" testfm/inventory
fi
if [[ "$TEST_UPSTREAM" = "true" ]]; then
    sed -i "s/foreman-maintain {0} {1} {2}/.\/foreman_maintain\/bin\/foreman-maintain {0} {1} {2}/g" testfm/base.py
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${SERVER_HOSTNAME} 'rm foreman_maintain/ -rvf'
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${SERVER_HOSTNAME} 'git clone https://github.com/theforeman/foreman_maintain.git'
    if [[ "$TEST_OPEN_PR" = 'true' ]]; then
        ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${SERVER_HOSTNAME} 'cd foreman_maintain; git fetch origin pull/'${PR_NUMBER}'/head:'${BRANCH_NAME}'; git checkout '${BRANCH_NAME}
    fi
fi
export ANSIBLE_HOST_KEY_CHECKING=False
if [ "${COMPONENT}" == "capsule" ]; then
    export PYTEST_MARKS=capsule
fi
set +e
if [ -n "${PYTEST_OPTIONS}" ]; then
    pytest -v --junit-xml=foreman-results.xml --ansible-host-pattern "${COMPONENT}" --ansible-user root --ansible-inventory testfm/inventory ${PYTEST_OPTIONS}
elif [ -n "${PYTEST_MARKS}" ]; then
    pytest -v --junit-xml=foreman-results.xml --ansible-host-pattern "${COMPONENT}" --ansible-user root --ansible-inventory testfm/inventory tests/ -m "${PYTEST_MARKS}"
else
    pytest -v --junit-xml=foreman-results.xml --ansible-host-pattern "${COMPONENT}" --ansible-user root --ansible-inventory testfm/inventory tests/
fi
set -e
if [[ "$TEST_UPSTREAM" != "true" ]]; then
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${SERVER_HOSTNAME} 'cat /var/log/foreman-maintain/foreman-maintain.log | grep -i error'
else
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${SERVER_HOSTNAME} 'cat ~/foreman_maintain/logs/foreman-maintain.log | grep -i error'
fi

pip install click jinja2

wget https://raw.githubusercontent.com/SatelliteQE/robottelo-ci/master/lib/python/satellite6-automation-report.py
mkdir templates
wget -O templates/report.html https://raw.githubusercontent.com/SatelliteQE/robottelo-ci/master/lib/python/templates/report.html
python satellite6-automation-report.py *.xml > report.txt
