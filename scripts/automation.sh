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
sed -i "s/project.*/project=$PRODUCT/" robottelo.properties

# Robottelo logging configuration
sed -i "s/'\(robottelo\).log'/'\1-${ENDPOINT}.log'/" logging.conf

make test-foreman-$ENDPOINT
