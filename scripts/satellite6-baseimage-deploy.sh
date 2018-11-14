pip install -r requirements.txt
source ${CONFIG_FILES}
source config/provisioning_environment.conf
source config/installation_environment.conf

HYPERVISORS=${HYPERVISORS:-$PROVISIONING_HOSTS}
set $HYPERVISORS # we can use 1st hypervisors as $1

eval $(ssh-agent -s) # setup ssh agent
ssh-add

fab -A -D -H "root@$1" "deploy_baseimage_by_url:$OS_URL,hypervisors=$HYPERVISORS,auth_keys_url=$AUTH_KEYS_URL,dns_server=$DNS_SERVER,disable_ipv6=$DISABLE_IPV6"

eval $(ssh-agent -s -k) # teardown ssh agent
