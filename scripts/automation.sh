pip install -U -r requirements.txt nose PyVirtualDisplay

# Project on YAML file is satellite6 or sam but robottelo just accept sam or
# sat as a project. Adjust the product variable properly
if [ "${PRODUCT}" = 'satellite6' ]; then
    PRODUCT='sat'
fi

cp ${ROBOTTELO_CONFIG} ./robottelo.properties

sed -i "s/{server_hostname}/${SERVER_HOSTNAME}/" robottelo.properties
sed -i "s/^project.*/project=${PRODUCT}/" robottelo.properties

# Robottelo logging configuration
sed -i "s/'\(robottelo\).log'/'\1-${ENDPOINT}.log'/" logging.conf

# upstream = 1 for Distributions: UPSTREAM (default in robottelo.properties)
# upstream = 0 for Distributions: DOWNSTREAM, CDN, BETA, ISO
if [[ "${DISTRIBUTION}" != *"UPSTREAM"* ]]; then
   sed -i "s/^upstream.*/upstream=false/" robottelo.properties
fi

make test-foreman-${ENDPOINT}
