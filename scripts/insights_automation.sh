pip install -U -r requirements.txt nose PyVirtualDisplay

# Project on YAML file is satellite6 or sam but robottelo just accept sam or
# sat as a project. Adjust the product variable properly
if [ "$PRODUCT" = 'satellite6' ]; then
    PRODUCT='sat'
fi

# API automation will run all data-driven tests
if [ "$ENDPOINT" = 'api' ]; then
    SMOKE=0
else
    SMOKE=1
fi

cp "${ROBOTTELO_CONFIG}" ./robottelo.properties

sed -i "s/server\.hostname.*/server\.hostname=${SERVER_HOSTNAME}/" robottelo.properties
sed -i "s/server.ssh.username.*/server.ssh.username=${SSH_USER}/" robottelo.properties

sed -i "s/admin.username.*/admin.username=${FOREMAN_ADMIN_USER}/" robottelo.properties
sed -i "s/admin.password.*/admin.password=${FOREMAN_ADMIN_PASSWORD}/" robottelo.properties

sed -i "s/smoke.*/smoke=$SMOKE/" robottelo.properties
sed -i "s/verbosity.*/verbosity=$VERBOSITY/" robottelo.properties
sed -i "s/locale.*/locale=$LOCALE/" robottelo.properties
sed -i "s/project.*/project=$PRODUCT/" robottelo.properties
sed -i "s/manifest.fake_url.*/manifest.fake_url=$MANIFEST_FAKE_URL/" robottelo.properties
sed -i "s/manifest.key_url*/manifest.key_url=$MANIFEST_KEY_URL/" robottelo.properties
sed -i "s/manifest.cert_url*/manifest.cert_url=$MANIFEST_CERT_URL/" robottelo.properties
sed -i "s/insights_el6repo*/insights_el6repo=$INSIGHTS_6_REPO/" robottelo.properties
sed -i "s/insights_el7repo*/insights_el7repo=$INSIGHTS_7_REPO/" robottelo.properties

nosetests -s -v tests.foreman.rhai.test_rhai

# Robottelo logging configuration
sed -i "s/'\(robottelo\).log'/'\1-${ENDPOINT}.log'/" logging.conf


