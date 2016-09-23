pip install -r requirements.txt
source ${CONFIG_FILES}
source config/fake_manifest.conf
source config/subscription_config.conf
fab -H "root@${MANIFEST_SERVER_HOSTNAME}" relink_manifest
