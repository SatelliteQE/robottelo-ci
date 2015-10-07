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

cp ${ROBOTTELO_CONFIG} ./robottelo.properties

sed -i "s/server\.hostname.*/server\.hostname=$SERVER_HOSTNAME/" robottelo.properties
sed -i "s/smoke.*/smoke=$SMOKE/" robottelo.properties
sed -i "s/verbosity.*/verbosity=$VERBOSITY/" robottelo.properties
sed -i "s/locale.*/locale=$LOCALE/" robottelo.properties
sed -i "s/^project.*/project=$PRODUCT/" robottelo.properties

# Robottelo logging configuration
sed -i "s/'\(robottelo\).log'/'\1-${ENDPOINT}.log'/" logging.conf

# upstream = 1 for Distributions: UPSTREAM (default in robottelo.properties)
# upstream = 0 for Distributions: DOWNSTREAM, CDN, BETA, ISO
if [[ "$DISTRIBUTION" != *"UPSTREAM"* ]]; then
   sed -i "s/upstream.*/upstream=0/" robottelo.properties
fi


# cdn = 1 for Distributions: CDN (default in robottelo.properties)
# cdn = 0 for Distributions: DOWNSTREAM, BETA, ISO, ZSTREAM
# Sync content and use the below repos only when DISTRIBUTION is not CDN
if [[ "$DISTRIBUTION" != *"CDN"* ]]; then
   # The below cdn flag is required by automation to flip between RH & custom syncs.
   sed -i "s/cdn.*/cdn=0/" robottelo.properties
   # Using # intentionally as TOOLS_REPO brings in URL which will have '/'.
   sed -i "s#sattools_repo.*#sattools_repo=$TOOLS_REPO#" robottelo.properties
fi

make test-foreman-$ENDPOINT
