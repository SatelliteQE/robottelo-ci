#!/usr/bin/env bash
# Admin Credentials
ADMIN_USER="admin"

ADMIN_PASSWORD=""

if [[ -z "${ADMIN_PASSWORD}" ]]; then
    ADMIN_PASSWORD="changeme"
fi

DOWNLOAD_POLICY="on_demand"

if [[ -z "${DOWNLOAD_POLICY}" ]]; then
    echo "You need to specify DOWNLOAD_POLICY for syncing content."
    exit 1
fi

# The below values get populated from the satellite6_libvirt_install.conf file.
# DOMAIN and SUBNET Variables.
SUBNET_NAME=""
SUBNET_RANGE=""
SUBNET_MASK=""
SUBNET_GATEWAY=""

if [[ -z "${SUBNET_NAME}" || -z "${SUBNET_RANGE}" || -z "${SUBNET_MASK}" || -z "${SUBNET_GATEWAY}" ]]; then
    echo "You need to specify SUBNET_NAME, SUBNET_RANGE, SUBNET_MASK and SUBNET_GATEWAY to be added as a subnet."
    exit 1
fi

CAPSULE_HOSTNAME=""

if [[ -z "${CAPSULE_HOSTNAME}" ]]; then
    echo "you need to specify CAPSULE_HOSTNAME for various tasks."
fi

ONLY_POPULATE_TEMPLATE="false"

if [[ "${ONLY_POPULATE_TEMPLATE}" = 'true' ]]; then
    if [[ -z "${STY}" || -z "${TMUX}" ]]; then
        echo "Assuming this script is not being run via Jenkins."
        echo "As this script could take anywhere between 2 to 5 hrs,"
        echo "Recommend to run this script from a SCREEN or TMUX Session Only."
        echo "Set ONLY_POPULATE_TEMPLATE to false in this script, to override without Screen or Tmux, if needed."
        echo "Example: 'yum install screen -y ; screen', should suffice."
        exit 1
    fi
fi


# Below are the default ID's of various Satellite6 entities.
# Basic Variables.
# ORG of ID 1 refers to 'Default Organization'
ORG=1
# LOC of ID 2 refers to 'Default Location'
LOC=2

# The default puppet environment which is "production"
PUPPET_ENV=1

# Depending upon the below values only certain commands get excuted in this script.
RHELOS=$(awk '{print $7}' /etc/redhat-release | cut -d . -f1)

SAT_VERSION=6.3


# Use this directly for ENV_VAR population and non side-effects on Satellite6 setup.
function satellite () {
    hammer -u "${ADMIN_USER}" -p "${ADMIN_PASSWORD}" "$@"
    if [ $? -ne 0 ]; then exit 1 ; fi
}

# Use this for all side-effects on a Satellite6 setup.
function satellite_runner () {
    [ ! -f /root/task_list.txt ] && touch /root/task_list.txt
    VAL=`echo "$@"`
    grep -Fxq "${VAL}" /root/task_list.txt > /dev/null
    RESULT=`echo $?`
    if [ "${RESULT}" -ne 0 ]; then
        satellite "$@"
        echo "$@" >> /root/task_list.txt
    fi
}

# TODO
# Update the Capsule DOWNLOAD_POLICY to sync content.
# satellite_runner settings set --name default_download_policy --value "${DOWNLOAD_POLICY}"

SMARTPROXYID=$(satellite --csv proxy list | grep "${CAPSULE_HOSTNAME}" | awk -F ',' '{print $1}')
echo SMART-PROXY ID: "${SMARTPROXYID}"

# Update Domain with Capsule's ID.
DOMAIN_ID=$(satellite --csv domain list --search "${CAPSULE_HOSTNAME#*.}" | grep -vi ID | awk -F "," '{print $1}')
echo DOMAIN_ID is "${DOMAIN_ID}"

echo Adding Smart-Proxy to Default location and to 'Default Organization'
satellite_runner capsule update --id "${SMARTPROXYID}" --organization-ids "${ORG}" --location-ids "${LOC}"

# Add Life-Cycle Environment to Capsule and Synchronize the content.
satellite_runner capsule content add-lifecycle-environment --id "${SMARTPROXYID}" --environment DEV --organization-id "${ORG}"
satellite_runner capsule content synchronize --id "${SMARTPROXYID}"



if [[ "${PROVISIONING_SETUP}" = "false" ]] ; then
    exit 0
fi

# Create subnet and associate various entities to it.
satellite_runner subnet create --name "${SUBNET_NAME}" --network "${SUBNET_RANGE}" --mask "${SUBNET_MASK}" --gateway "${SUBNET_GATEWAY}" --dns-id "${SMARTPROXYID}" --dhcp-id "${SMARTPROXYID}" --tftp-id "${SMARTPROXYID}" --domain-ids "${DOMAIN_ID}" --ipam DHCP --boot-mode DHCP --organization-ids="${ORG}" --location-ids="${LOC}"

# TODO Need to investigate
# echo Assign Default Organization and Default Location to Production Puppet Environment.
# satellite_runner environment update --organization-ids "${ORG}" --location-ids "${LOC}" --id 1

# TODO Need to investigate
# Import puppet-classes from default capsule  to environment.
# satellite_runner capsule import-classes --id 1 --environment-id 1

# Populate the RHEL6 and RHEL7 OS ID

RHEL7_OS_ID=$(satellite --csv os list | grep "7.5" | cut -d ',' -f1 | grep -vi "^id")
echo "RHEL7 OS ID is: ${RHEL7_OS_ID}"

RHEL6_OS_ID=$(satellite --csv os list | grep "6.9" | cut -d ',' -f1 | grep -vi "^id")
echo "RHEL6 OS ID is: ${RHEL6_OS_ID}"

if [ "${SAT_VERSION}" = "6.3" ]; then

    RHEL7_KS_ID=$(satellite --csv repository list | awk -F "," '/Server Kickstart x86_64 7/ {print $1}')
    echo "RHEL7 KS ID is: ${RHEL7_KS_ID}"

    RHEL6_KS_ID=$(satellite --csv repository list | awk -F "," '/Server Kickstart x86_64 6/ {print $1}')
    echo "RHEL6 KS ID is: ${RHEL6_KS_ID}"

    # Create Host-Groups and associate activation key as a parameter.

    satellite_runner hostgroup create --name='RHEL 6 Server 64-bit Capsule HG' --content-view='RHEL 6 CV' --environment-id="${PUPPET_ENV}" --lifecycle-environment='DEV' --content-source-id="${SMARTPROXYID}" --puppet-proxy="${CAPSULE_HOSTNAME}" --puppet-ca-proxy="${CAPSULE_HOSTNAME}" --query-organization-id="${ORG}" --puppet-classes='access_insights_client,foreman_scap_client' --domain-id=${DOMAIN_ID} --subnet="${SUBNET_NAME}" --architecture='x86_64' --operatingsystem-id=${RHEL6_OS_ID} --partition-table='Kickstart default' --location-ids="${LOC}" --pxe-loader 'PXELinux BIOS' --kickstart-repository-id=${RHEL6_KS_ID}

    satellite_runner hostgroup set-parameter --hostgroup='RHEL 6 Server 64-bit Capsule HG' --name='kt_activation_keys' --value='ak-rhel-6'

    satellite_runner hostgroup create --name='RHEL 7 Server 64-bit Capsule HG' --content-view='RHEL 7 CV' --environment-id="${PUPPET_ENV}" --lifecycle-environment='DEV' --content-source-id="${SMARTPROXYID}" --puppet-proxy="${CAPSULE_HOSTNAME}" --puppet-ca-proxy="${CAPSULE_HOSTNAME}" --query-organization-id="${ORG}" --puppet-classes='access_insights_client,foreman_scap_client' --domain-id=${DOMAIN_ID} --subnet="${SUBNET_NAME}" --architecture='x86_64' --operatingsystem-id=${RHEL7_OS_ID} --partition-table='Kickstart default' --location-ids="${LOC}" --pxe-loader 'PXELinux BIOS' --kickstart-repository-id=${RHEL7_KS_ID}

    satellite_runner hostgroup set-parameter --hostgroup='RHEL 7 Server 64-bit Capsule HG' --name='kt_activation_keys' --value='ak-rhel-7'
else
    # Assign Default Location to RHEL6 and RHEL7 medium.
    # NOTE: Medium does not appear to exist for Satellite6.3

    echo Assign Default Location to RHEL6 and RHEL7 medium.
    RHEL7_MEDIUM_ID=$(satellite --csv medium list --search='name~"Linux_7_Server_Kickstart_x86_64"' | cut -d ',' -f1 | grep -vi 'id')
    satellite_runner medium update --location-ids "${LOC}" --id "${RHEL7_MEDIUM_ID}"
    RHEL6_MEDIUM_ID=$(satellite --csv medium list --search='name~"Linux_6_Server_Kickstart_x86_64"' | cut -d ',' -f1 | grep -vi 'id')
    satellite_runner medium update --location-ids "${LOC}" --id "${RHEL6_MEDIUM_ID}"

    # Create Host-Groups and associate activation key as a parameter.
    satellite_runner hostgroup create --name='RHEL 6 Server 64-bit Capsule HG' --content-view='RHEL 6 CV' --environment-id="${PUPPET_ENV}" --lifecycle-environment='DEV' --content-source-id="${SMARTPROXYID}" --puppet-proxy="${CAPSULE_HOSTNAME}" --puppet-ca-proxy="${CAPSULE_HOSTNAME}" --organization-id="${ORG}" --puppet-classes='access_insights_client,foreman_scap_client' --domain-id=${DOMAIN_ID} --subnet="${SUBNET_NAME}" --architecture='x86_64' --operatingsystem-id=${RHEL6_OS_ID} --partition-table='Kickstart default' --location-ids="${LOC}" --medium-id=${RHEL6_MEDIUM_ID}

    satellite_runner hostgroup set-parameter --hostgroup='RHEL 6 Server 64-bit Capsule HG' --name='kt_activation_keys' --value='ak-rhel-6'

    satellite_runner hostgroup create --name='RHEL 7 Server 64-bit Capsule HG' --content-view='RHEL 7 CV' --environment-id="${PUPPET_ENV}" --lifecycle-environment='DEV' --content-source-id="${SMARTPROXYID}" --puppet-proxy="${CAPSULE_HOSTNAME}" --puppet-ca-proxy="${CAPSULE_HOSTNAME}" --organization-id="${ORG}" --puppet-classes='access_insights_client,foreman_scap_client' --domain-id=${DOMAIN_ID} --subnet="${SUBNET_NAME}" --architecture='x86_64' --operatingsystem-id=${RHEL7_OS_ID} --partition-table='Kickstart default' --location-ids="${LOC}" --medium-id=${RHEL7_MEDIUM_ID}

    satellite_runner hostgroup set-parameter --hostgroup='RHEL 7 Server 64-bit Capsule HG' --name='kt_activation_keys' --value='ak-rhel-7'
fi

satellite_runner host-collection create --name="RHEL 7 Host collection Capsule" --organization-id "${ORG}"
echo "RHEL 7 Host collection Capsule created"
satellite_runner host-collection create --name="RHEL 6 Host collection Capsule" --organization-id "${ORG}"
echo "RHEL 6 Host collection Capsule created"
