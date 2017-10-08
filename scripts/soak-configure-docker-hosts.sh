# Create the needed HostGroup and ActivationKeys
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@"${SATELLITE_SERVER_HOSTNAME}" hammer -u admin -p changeme hostgroup create --name="HostGroup" --content-view="SatPerfContentView" --lifecycle-environment=Library --content-source-id=1 --puppet-proxy="${SATELLITE_SERVER_HOSTNAME}" --puppet-ca-proxy="${SATELLITE_SERVER_HOSTNAME}" --query-organization-id=1 --location-ids=2

ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@"${SATELLITE_SERVER_HOSTNAME}" hammer -u admin -p changeme activation-key create --name="ActivationKey" --content-view="SatPerfContentView" --lifecycle-environment=Library --organization-id=1

ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@"${SATELLITE_SERVER_HOSTNAME}" hammer -u admin -p changeme activation-key add-subscription --name="ActivationKey" --organization-id=1 --subscription-id=$(hammer -u admin -p changeme --csv subscription list --organization-id=1 | grep -i "Red Hat Satellite Employee Subscription" |  awk -F "," '{print $1}' | grep -vi id)

ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@"${SATELLITE_SERVER_HOSTNAME}" hammer -u admin -p changeme activation-key add-subscription --name="ActivationKey" --organization-id=1 --subscription-id=$(hammer -u admin -p changeme --csv subscription list --organization-id=1 | grep "Sat6 Tools" | awk -F "," '{print $1}' | grep -vi id)

# Setup the docker host, for things like networking/docker0
# Ensure the 10gnic being passed is a physical interface and not a Bridge.
ansible-playbook --private-key conf/id_rsa_soak -i conf/hosts.ini playbooks/satellite/docker-host.yaml

# Downloads the "r7perfsat" docker image and starts containers depending upon the DOCKER_HOST_COUNT
ansible-playbook --private-key conf/id_rsa_soak -i conf/hosts.ini playbooks/satellite/docker-tierup.yaml

# Would register the containers depending upon the COUNT to sat6 via the bootstrap.py script.
for i in $(seq 1 ${DOCKER_HOST_COUNT}); do  ansible-playbook --forks 100 -i conf/hosts.ini playbooks/tests/registrations.yaml -e "size=${DOCKER_HOST_COUNT} resting=0"; done
