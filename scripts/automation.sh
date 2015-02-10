pip install -U -r requirements.txt nose PyVirtualDisplay
source $FAKE_CERT_CONFIG
source $ROBOTTELO_CONFIG

cp robottelo.properties.sample robottelo.properties

sed -i "s/server\.hostname.*/server\.hostname=$SERVER_HOSTNAME/" robottelo.properties
sed -i "s/server\.ssh\.key_private.*/server\.ssh\.key_private=\/home\/jenkins\/.ssh\/id_rsa/" robottelo.properties
sed -i "s/smoke.*/smoke=$SMOKE/" robottelo.properties
sed -i "s/verbosity.*/verbosity=$VERBOSITY/" robottelo.properties
sed -i "s/locale.*/locale=$LOCALE/" robottelo.properties
sed -i "s/virtual_display.*/virtual_display=1/" robottelo.properties
sed -i "s/window_manager_command.*/window_manager_command=fluxbox/" robottelo.properties

# Manifests configuration
sed -i "s|manifest\.key_url.*|manifest\.key_url=$FAKE_MANIFEST_KEY_URL|" robottelo.properties
sed -i "s|manifest\.fake_url.*|manifest\.fake_url=$FAKE_MANIFEST_URL|" robottelo.properties
sed -i "s|manifest\.cert_url.*|manifest\.cert_url=$FAKE_MANIFEST_CERT_URL|" robottelo.properties

# Clients configuration
sed -i "s/provisioning_server.*/provisioning_server=$PROVISIONING_SERVER/" robottelo.properties

make test-foreman-$ENDPOINT
