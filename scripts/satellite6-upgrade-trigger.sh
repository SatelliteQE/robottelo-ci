pip install -U pip

if [ "$(curl --version | grep NSS 2>/dev/null)" ]; then
    pip install --compile --install-option="--with-nss" pycurl
else
    pip install --compile --install-option="--with-openssl" pycurl
fi

pip install -r requirements.txt
source "${{OPENSTACK_CONFIG}}"
source "${{SUBSCRIPTION_CONFIG}}"
export OS_echo="$(VERSION {os} | cut -dl -f2)"
export BASE_URL="${{SATELLITE6_REPO}}"
export CAPSULE_URL="${{CAPSULE_REPO}}"
export TOOLS_URL="${{TOOLS_REPO}}"
fab -u root product_upgrade:'capsule','sat_jenkins','sat_upgrade_{os}_auto',"sat${{COMPOSE}}-qe-{os}",'m1.large','cap-upgrade-{os}-auto',"capsule${{COMPOSE}}-qe-{os}",'m1.large'
