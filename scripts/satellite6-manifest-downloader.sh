pip install -r requirements.txt
source ${FAKE_CERT_CONFIG}
source ${SUBSCRIPTION_CONFIG}
fab -H "root@${MANIFEST_SERVER_HOSTNAME}" relink_manifest
