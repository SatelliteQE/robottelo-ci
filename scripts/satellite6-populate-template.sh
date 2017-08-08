#!/usr/bin/env bash
# Admin Credentials
ADMIN_USER="admin"
ADMIN_PASSWORD="changeme"

# The below values get populated from the compute_resources.conf file.
# Compute Resource Variables.
COMPUTE_RESOURCE_NAME_LIBVIRT="libvirt"
LIBVIRT_URL=""

if [[ -z "$LIBVIRT_URL" ]]; then
    echo "You need to specify the LIBVIRT_URL to be used as Compute Resource."
    exit 1
fi

# RHEVM Compute Resource Variables.
RHEV_URL=""
RHEV_USERNAME=""
RHEV_PASSWORD=""
RHEV_DATACENTER_UUID=""

if [[ -z "$RHEV_URL" || -z "$RHEV_USERNAME" || -z "$RHEV_PASSWORD" || -z "$RHEV_DATACENTER_UUID" ]]; then
    echo "You need to specify RHEV_URL, RHEV_USERNAME, RHEV_PASSWORD and RHEV_DATACENTER_UUID to be used as Compute Resource."
    exit 1
fi

# Openstack Compute Resource.
OS_URL=""
OS_USERNAME=""
OS_PASSWORD=""

if [[ -z "$OS_URL" || -z "$OS_USERNAME" || -z "$OS_PASSWORD" ]]; then
    echo "You need to specify OS_URL, OS_USERNAME, OS_PASSWORD to be used as Compute Resource."
    exit 1
fi


# The below values get populated from the satellite6_libvirt_install.conf file.
# DOMAIN and SUBNET Variables.
SUBNET_NAME=""
SUBNET_RANGE=""
SUBNET_MASK=""
SUBNET_GATEWAY=""

if [[ -z "$SUBNET_NAME" || -z "$SUBNET_RANGE" || -z "$SUBNET_MASK" || -z "$SUBNET_GATEWAY" ]]; then
    echo "You need to specify SUBNET_NAME, SUBNET_RANGE, SUBNET_MASK and SUBNET_GATEWAY to be added as a subnet."
    exit 1
fi

HTTP_SERVER_HOSTNAME=""

if [[ -z "$HTTP_SERVER_HOSTNAME" ]]; then
    echo "You need to specify HTTP_SERVER_HOSTNAME which hosts the manifest file."
    exit 1
fi

DOWNLOAD_POLICY=""

if [[ -z "$DOWNLOAD_POLICY" ]]; then
    echo "You need to specify DOWNLOAD_POLICY for syncing content."
    exit 1
fi

SATELLITE_DISTRIBUTION=""

if [[ -z "$SATELLITE_DISTRIBUTION" ]]; then
    echo "You need to speciy SATELLITE_DISTRIBUTION to sync the content from."
    exit 1
fi

# Manifest details
MANIFEST_LOCATION="${HTTP_SERVER_HOSTNAME}/manifests/manifest-latest.zip"

# Below are the default ID's of various Satellite6 entities.
# Basic Variables.
# ORG of ID 1 refers to 'Default Organization'
ORG=1 
# LOC of ID 2 refers to 'Default Location'
LOC=2

# The ID of the Default/Internal capsule, which is Satellite6 itself.
CAPSULE_ID=1

# The default puppet environment which is "production"
PUPPET_ENV=1


# Depending upon the below values only certain commands get excuted in this script.
RHELOS=$(awk '{print $7}' /etc/redhat-release | cut -d . -f1)

SAT_VERSION=6.3

# Plan is to install satellite6 with only RHEL6-x86_4 and RHEL7-x86_64 content
# TODO: If more content is planned to be synced, set it under MINIMAL_INSTALL="false".
MINIMAL_INSTALL="true"


# The below values get populated from the sat6_repo_urls.conf file.
# Sat6 Tools and Capsule Repo Variables
if [ "${SATELLITE_DISTRIBUTION}" = "GA" ]; then
    RHEL6_TOOLS_PRD="Red Hat Enterprise Linux Server"
    RHEL6_TOOLS_REPO="Red Hat Satellite Tools ${SAT_VERSION} for RHEL 6 Server RPMs x86_64"
    RHEL7_TOOLS_PRD="Red Hat Enterprise Linux Server"
    RHEL7_TOOLS_REPO="Red Hat Satellite Tools ${SAT_VERSION} for RHEL 7 Server RPMs x86_64"
    SAT6C6_PRODUCT="Red Hat Satellite Capsule"
    CAPSULE6_REPO="Red Hat Satellite Capsule ${SAT_VERSION} for RHEL 6 Server RPMs x86_64"
    SAT6C7_PRODUCT="Red Hat Satellite Capsule"
    CAPSULE7_REPO="Red Hat Satellite Capsule ${SAT_VERSION} for RHEL 7 Server RPMs x86_64"
else
    RHEL6_TOOLS_PRD=Sat6Tools6
    RHEL6_TOOLS_REPO=sat6tool6
    RHEL6_TOOLS_URL="rhel6_tools_url"
    RHEL7_TOOLS_PRD=Sat6Tools7
    RHEL7_TOOLS_REPO=sat6tool7
    RHEL7_TOOLS_URL="rhel7_tools_url"
    SAT6C6_PRODUCT=Sat6Capsule6
    CAPSULE6_REPO=capsule6
    CAPSULE6_URL="capsule6_url"
    SAT6C7_PRODUCT=Sat6Capsule7
    CAPSULE7_REPO=capsule7
    CAPSULE7_URL="capsule7_url"
fi


function satellite () {
    hammer -u ${ADMIN_USER} -p ${ADMIN_PASSWORD} "$@"
}

function create-repo () {
    PRODUCT=$1
    REPO=$2
    URL=$3
    echo Creating Product "${PRODUCT}"
    satellite product create --name "${PRODUCT}" --organization-id "${ORG}"
    PRODUCT_ID=$(satellite --csv product list --organization-id "${ORG}" --name "${PRODUCT}" | tail -n1 | cut -f1 -d,)
    echo Creating Repository "${REPO}"
    satellite repository create --name "${REPO}" --url "${URL}" --product-id "${PRODUCT_ID}" --content-type yum --publish-via-http true
    REPO_ID=$(satellite --csv repository list --organization-id "${ORG}" --product-id "${PRODUCT_ID}" | tail -n1 | cut -f1 -d,)
    echo Synchronizing repository "${REPO}"
    satellite repository synchronize --id "${REPO_ID}"
}

# Create 2 lifecycle-environments
satellite lifecycle-environment create --name='DEV' --prior='Library' --organization-id="${ORG}"
satellite lifecycle-environment create --name='QE' --prior='DEV' --organization-id="${ORG}"
satellite lifecycle-environment create --name='PROD' --prior='QE' --organization-id="${ORG}"

# Update the DOWNLOAD_POLICY to sync content.
satellite settings set --name default_download_policy --value "${DOWNLOAD_POLICY}"

# Fetch the manifest from server.
wget -O "${HOME}"/manifest-latest.zip "${MANIFEST_LOCATION}"

# Import Manifest.
satellite subscription upload --organization-id "${ORG}" --file "${HOME}"/manifest-latest.zip

# Enable Red Hat repositories
# Kickstart trees
satellite repository-set enable --name="Red Hat Enterprise Linux 7 Server (Kickstart)" --basearch="x86_64" --releasever="7.3" --product "Red Hat Enterprise Linux Server" --organization-id="${ORG}"
satellite repository-set enable --name="Red Hat Enterprise Linux 6 Server (Kickstart)" --basearch="x86_64" --releasever="6.8" --product "Red Hat Enterprise Linux Server" --organization-id="${ORG}"

# 'Base' OS RPMs
satellite repository-set enable --name="Red Hat Enterprise Linux 7 Server (RPMs)" --basearch="x86_64" --releasever="7Server" --product "Red Hat Enterprise Linux Server" --organization-id="${ORG}"
satellite repository-set enable --name="Red Hat Enterprise Linux 6 Server (RPMs)" --basearch="x86_64" --releasever="6Server" --product "Red Hat Enterprise Linux Server" --organization-id="${ORG}"

# Satellite6 CDN RPMS
if [ "${SATELLITE_DISTRIBUTION}" = "GA" ]; then
    # Satellite6 Tools RPMS
    satellite repository-set enable --name="Red Hat Satellite Tools ${SAT_VERSION} (for RHEL 7 Server) (RPMs)" --basearch="x86_64" --product "Red Hat Enterprise Linux Server" --organization-id="${ORG}"
    satellite repository-set enable --name="Red Hat Satellite Tools ${SAT_VERSION} (for RHEL 6 Server) (RPMs)" --basearch="x86_64" --product "Red Hat Enterprise Linux Server" --organization-id="${ORG}"
    # Satellite6 Capsule RPMS
    satellite repository-set enable --name="Red Hat Satellite Capsule ${SAT_VERSION} (for RHEL 7 Server) (RPMs)" --basearch="x86_64" --product "Red Hat Satellite Capsule" --organization-id="${ORG}"
    satellite repository-set enable --name="Red Hat Satellite Capsule ${SAT_VERSION} (for RHEL 7 Server) (RPMs)" --basearch="x86_64" --product "Red Hat Satellite Capsule" --organization-id="${ORG}"
fi

# Synchronize all repositories except for Puppet repositories which don't have URLs
for repo in $(satellite --csv repository list --organization-id="${ORG}" --per-page=1000 | grep -vi 'puppet' | cut -d ',' -f 1 | grep -vi '^ID'); do
    satellite repository synchronize --id "${repo}" --organization-id="${ORG}"
done

# Create Repos and Sync Repositories.
# Create both Tools for RHEL6 and RHEL7 and Capsule for RHEL6 and RHEL7

if [ "${SATELLITE_DISTRIBUTION}" != "GA" ]; then
    create-repo "${RHEL6_TOOLS_PRD}" "${RHEL6_TOOLS_REPO}" "${RHEL6_TOOLS_URL}"
    create-repo "${RHEL7_TOOLS_PRD}" "${RHEL7_TOOLS_REPO}" "${RHEL7_TOOLS_URL}"
    create-repo "${SAT6C6_PRODUCT}" "${CAPSULE6_REPO}" "${CAPSULE6_URL}"
    create-repo "${SAT6C7_PRODUCT}" "${CAPSULE7_REPO}" "${CAPSULE7_URL}"
fi

#Create content views
satellite content-view create --name 'RHEL 7 CV' --organization-id="${ORG}"
satellite content-view create --name 'RHEL 6 CV' --organization-id="${ORG}"
satellite content-view create --name 'Capsule RHEL 7 CV' --organization-id="${ORG}"

# Add content to content views
# RHEL 7
satellite  content-view add-repository --name='RHEL 7 CV' --organization-id="${ORG}" --product='Red Hat Enterprise Linux Server' --repository='Red Hat Enterprise Linux 7 Server Kickstart x86_64 7.3'
satellite  content-view add-repository --name='RHEL 7 CV' --organization-id="${ORG}" --product='Red Hat Enterprise Linux Server' --repository='Red Hat Enterprise Linux 7 Server RPMs x86_64 7Server'
satellite  content-view add-repository --name='RHEL 7 CV' --organization-id="${ORG}" --product="${RHEL7_TOOLS_PRD}" --repository="${RHEL7_TOOLS_REPO}"
satellite  content-view publish --name='RHEL 7 CV' --organization-id="${ORG}"
satellite  content-view version promote --content-view='RHEL 7 CV' --organization-id="${ORG}" --to-lifecycle-environment=DEV --from-lifecycle-environment="Library"

# RHEL 6
satellite  content-view add-repository --name='RHEL 6 CV' --organization-id="${ORG}" --product='Red Hat Enterprise Linux Server' --repository='Red Hat Enterprise Linux 6 Server Kickstart x86_64 6.8'
satellite  content-view add-repository --name='RHEL 6 CV' --organization-id="${ORG}" --product='Red Hat Enterprise Linux Server' --repository='Red Hat Enterprise Linux 6 Server RPMs x86_64 6Server'
satellite  content-view add-repository --name='RHEL 6 CV' --organization-id="${ORG}" --product="${RHEL6_TOOLS_PRD}" --repository="${RHEL6_TOOLS_REPO}"
satellite  content-view publish --name='RHEL 6 CV' --organization-id="${ORG}"
satellite  content-view version promote --content-view='RHEL 6 CV' --organization-id="${ORG}" --to-lifecycle-environment=DEV --from-lifecycle-environment="Library"

if [ "${RHELOS}" = "7" ]; then
    # Capsule RHEL7
    satellite  content-view add-repository --name='Capsule RHEL 7 CV' --organization-id="${ORG}" --product='Red Hat Enterprise Linux Server' --repository='Red Hat Enterprise Linux 7 Server RPMs x86_64 7Server'
    satellite  content-view add-repository --name='Capsule RHEL 7 CV' --organization-id="${ORG}" --product="${RHEL7_TOOLS_PRD}" --repository="${RHEL7_TOOLS_REPO}"
    satellite  content-view add-repository --name='Capsule RHEL 7 CV' --organization-id="${ORG}" --product="${SAT6C7_PRODUCT}" --repository="${CAPSULE7_REPO}"
    satellite  content-view publish --name='Capsule RHEL 7 CV' --organization-id="${ORG}"
    satellite  content-view version promote --content-view='Capsule RHEL 7 CV' --organization-id="${ORG}" --to-lifecycle-environment=DEV --from-lifecycle-environment="Library"
else
    # Capsule RHEL6
    satellite  content-view add-repository --name='Capsule RHEL 6 CV' --organization-id="${ORG}" --product='Red Hat Enterprise Linux Server' --repository='Red Hat Enterprise Linux 6 Server RPMs x86_64 6Server'
    satellite  content-view add-repository --name='Capsule RHEL 6 CV' --organization-id="${ORG}" --product="${RHEL6_TOOLS_PRD}" --repository="${RHEL6_TOOLS_REPO}"
    satellite  content-view add-repository --name='Capsule RHEL 6 CV' --organization-id="${ORG}" --product="${SAT6C6_PRODUCT}" --repository="${CAPSULE6_REPO}"
    satellite  content-view publish --name='Capsule RHEL 6 CV' --organization-id="${ORG}"
    satellite  content-view version promote --content-view='Capsule RHEL 6 CV' --organization-id="${ORG}" --to-lifecycle-environment=DEV --from-lifecycle-environment="Library"
fi

# Activation Keys
# Create activation keys
satellite  activation-key create --name 'ak-rhel-7' --content-view='RHEL 7 CV' --lifecycle-environment='DEV' --organization-id="${ORG}"
satellite  activation-key create --name 'ak-rhel-6' --content-view='RHEL 6 CV' --lifecycle-environment='DEV' --organization-id="${ORG}"
satellite  activation-key create --name "ak-capsule-${RHELOS}" --content-view="Capsule RHEL ${RHELOS} CV" --lifecycle-environment='DEV' --organization-id="${ORG}"

satellite  activation-key update --name 'ak-rhel-7' --auto-attach no --organization-id="${ORG}"
satellite  activation-key update --name 'ak-rhel-6' --auto-attach no --organization-id="${ORG}"
satellite  activation-key update --name "ak-capsule-${RHELOS}" --auto-attach no --organization-id="${ORG}"

# Add both RHEL6 and RHEL7 Activation keys.
# RHEL 7 activation key
RHEL_SUBS_ID=$(satellite --csv subscription list --organization-id=1 | grep -i "Red Hat Enterprise Linux Server, Premium (8 sockets) (Unlimited guests)" |  awk -F "," '{print $1}' | grep -vi id)
TOOLS7_SUBS_ID=$(satellite  --csv subscription list --organization-id=1 --search="name=${RHEL7_TOOLS_PRD}" | awk -F "," '{print $1}' | grep -vi id)
satellite  activation-key add-subscription --name='ak-rhel-7' --organization-id="${ORG}" --subscription-id="${RHEL_SUBS_ID}"

# As SATELLITE TOOLS REPO is already part of RHEL subscription.
if [ "${SATELLITE_DISTRIBUTION}" != "GA" ]; then
    satellite  activation-key add-subscription --name='ak-rhel-7' --organization-id="${ORG}" --subscription-id="${TOOLS7_SUBS_ID}"
fi


# RHEL 6 activation key
TOOLS6_SUBS_ID=$(satellite  --csv subscription list --organization-id=1 --search="name=${RHEL6_TOOLS_PRD}" | awk -F "," '{print $1}' | grep -vi id)
satellite  activation-key add-subscription --name='ak-rhel-6' --organization-id="${ORG}" --subscription-id="${RHEL_SUBS_ID}"

# As SATELLITE TOOLS REPO is already part of RHEL subscription.
if [ "${SATELLITE_DISTRIBUTION}" != "GA" ]; then
    satellite  activation-key add-subscription --name='ak-rhel-6' --organization-id="${ORG}" --subscription-id="${TOOLS6_SUBS_ID}"
fi


# Add both RHEL6 and RHEL7 Capsule Activation keys.
SATELLITE_SUBS_ID=$(satellite --csv subscription list --organization-id=1 | grep -i "Red Hat Satellite Employee Subscription" |  awk -F "," '{print $1}' | grep -vi id)
if [ "${RHELOS}" = "7" ]; then

    # Capsule 7 activation key
    if [ "${SATELLITE_DISTRIBUTION}" != "GA" ]; then
        CAPSULE7_SUBS_ID=$(satellite  --csv subscription list --organization-id=1 --search="name=${SAT6C7_PRODUCT}" | awk -F "," '{print $1}' | grep -vi id)
    else
	CAPSULE7_SUBS_ID="${SATELLITE_SUBS_ID}"
    fi

    satellite  activation-key add-subscription --name='ak-capsule-7' --organization-id="${ORG}" --subscription-id="${RHEL_SUBS_ID}"
    satellite  activation-key add-subscription --name='ak-capsule-7' --organization-id="${ORG}" --subscription-id="${CAPSULE7_SUBS_ID}"

    # As SATELLITE TOOLS REPO is already part of RHEL subscription.
    if [ "${SATELLITE_DISTRIBUTION}" != "GA" ]; then
        satellite  activation-key add-subscription --name='ak-capsule-7' --organization-id="${ORG}" --subscription-id="${TOOLS7_SUBS_ID}"
    fi
else
    # Capsule 6 activation key
    if [ "${SATELLITE_DISTRIBUTION}" != "GA" ]; then
        CAPSULE6_SUBS_ID=$(satellite  --csv subscription list --organization-id=1 --search="name=${SAT6C6_PRODUCT}" | awk -F "," '{print $1}' | grep -vi id)
    else
	CAPSULE6_SUBS_ID="${SATELLITE_SUBS_ID}"
    fi

    satellite  activation-key add-subscription --name='ak-capsule-6' --organization-id="${ORG}" --subscription-id="${RHEL_SUBS_ID}"
    satellite  activation-key add-subscription --name='ak-capsule-6' --organization-id="${ORG}" --subscription-id="${CAPSULE6_SUBS_ID}"

    # As SATELLITE TOOLS REPO is already part of RHEL subscription.
    if [ "${SATELLITE_DISTRIBUTION}" != "GA" ]; then
        satellite  activation-key add-subscription --name='ak-capsule-6' --organization-id="${ORG}" --subscription-id="${TOOLS6_SUBS_ID}"
    fi
fi

# Update Domain with Capsule's ID.
DOMAIN_ID=$(satellite --csv domain list --search "$(hostname -d)" | grep -vi ID | awk -F "," '{print $1}')
echo DOMAIN_ID is "${DOMAIN_ID}"
satellite domain update --id "${DOMAIN_ID}" --organization-ids "${ORG}" --location-ids "${LOC}" --dns-id 1

# Create subnet and associate various entities to it.
satellite subnet create --name "${SUBNET_NAME}" --network "${SUBNET_RANGE}" --mask "${SUBNET_MASK}" --gateway "${SUBNET_GATEWAY}" --dns-id "${CAPSULE_ID}" --dhcp-id "${CAPSULE_ID}" --tftp-id "${CAPSULE_ID}" --domain-ids "${DOMAIN_ID}" --ipam DHCP --boot-mode DHCP --organization-ids="${ORG}" --location-ids="${LOC}"

# Compute Resource Creations

# Create Libvirt CR
satellite compute-resource create --name "${COMPUTE_RESOURCE_NAME_LIBVIRT}" --provider Libvirt --url "${LIBVIRT_URL}" --location-ids "${LOC}" --organization-ids "${ORG}" --set-console-password false

# Create Ovirt CR
satellite compute-resource create --provider Ovirt --url "${RHEV_URL}" --name "rhevm1" --user "${RHEV_USERNAME}" --password "${RHEV_PASSWORD}" --location-ids "${LOC}" --organization-ids "${ORG}" --uuid "${RHEV_DATACENTER_UUID}"

# Create OpenStack CR
satellite compute-resource create --name openstack_provider --provider Openstack --url "${OS_URL}" --location-ids "${LOC}" --organization-ids "${ORG}" --user "${OS_USERNAME}" --password "${OS_PASSWORD}"

# Associations

SMARTPROXYID=$(satellite --csv proxy list | grep "${HOSTNAME}" | awk -F ',' '{print $1}')
echo SMART-PROXY ID: "${SMARTPROXYID}"

echo Adding Smart-Proxy to Default location and to 'Default Organization'
satellite location add-smart-proxy --id="${LOC}" --smart-proxy-id="${SMARTPROXYID}"
satellite organization add-smart-proxy --id="${ORG}" --smart-proxy-id="${SMARTPROXYID}"

echo Adding Default Organization to Default Location
satellite location add-organization --id="${LOC}" --organization='Default Organization'

echo Assign Default ORganization and Default Location to Production Puppet Environment.
satellite environment update --organization-ids "${ORG}" --location-ids "${LOC}" --id 1

# Import puppet-classes from default capsule  to environment.
satellite capsule import-classes --id 1 --environment-id 1

# Populate the RHEL6 and RHEL7 OS ID

RHEL7_OS_ID=$(satellite --csv os list | grep "RedHat 7" | cut -d ',' -f1 | grep -vi "^id")
echo "RHEL7 OS ID is: ${RHEL7_OS_ID}"

RHEL6_OS_ID=$(satellite --csv os list | grep "RedHat 6" | cut -d ',' -f1 | grep -vi "^id")
echo "RHEL6 OS ID is: ${RHEL6_OS_ID}"


if [ "${SAT_VERSION}" = "6.3" ]; then
    # Create Host-Groups and associate activation key as a parameter.

    satellite hostgroup create --name='RHEL 6 Server 64-bit HG' --content-view='RHEL 6 CV' --environment-id="${PUPPET_ENV}" --lifecycle-environment='DEV' --content-source-id="${CAPSULE_ID}" --puppet-proxy="$(hostname)" --puppet-ca-proxy="$(hostname)" --query-organization-id="${ORG}" --puppet-classes='access_insights_client,foreman_scap_client' --domain-id="${DOMAIN_ID}" --subnet="${SUBNET_NAME}" --architecture='x86_64' --operatingsystem-id="${RHEL6_OS_ID}" --partition-table='Kickstart default' --location-ids="${LOC}"

    satellite hostgroup set-parameter --hostgroup='RHEL 6 Server 64-bit HG' --name='kt_activation_keys' --value='ak-rhel-6'

    satellite hostgroup create --name='RHEL 7 Server 64-bit HG' --content-view='RHEL 7 CV' --environment-id="${PUPPET_ENV}" --lifecycle-environment='DEV' --content-source-id="${CAPSULE_ID}" --puppet-proxy="$(hostname)" --puppet-ca-proxy="$(hostname)" --query-organization-id="${ORG}" --puppet-classes='access_insights_client,foreman_scap_client' --domain-id="${DOMAIN_ID}" --subnet="${SUBNET_NAME}" --architecture='x86_64' --operatingsystem-id="${RHEL7_OS_ID}" --partition-table='Kickstart default' --location-ids="${LOC}"

    satellite hostgroup set-parameter --hostgroup='RHEL 7 Server 64-bit HG' --name='kt_activation_keys' --value='ak-rhel-7'
else
    # Assign Default Location to RHEL6 and RHEL7 medium.
    # NOTE: Medium does not appeat to exist for Satellite6.3

    echo Assign Default Location to RHEL6 and RHEL7 medium.
    RHEL7_MEDIUM_ID=$(satellite --csv medium list --search='name~"Linux_7_Server_Kickstart_x86_64"' | cut -d ',' -f1 | grep -vi 'id')
    satellite medium update --location-ids "${LOC}" --id "${RHEL7_MEDIUM_ID}"
    RHEL6_MEDIUM_ID=$(satellite --csv medium list --search='name~"Linux_6_Server_Kickstart_x86_64"' | cut -d ',' -f1 | grep -vi 'id')
    satellite medium update --location-ids "${LOC}" --id "${RHEL6_MEDIUM_ID}"

    # Create Host-Groups and associate activation key as a parameter.
    satellite hostgroup create --name='RHEL 6 Server 64-bit HG' --content-view='RHEL 6 CV' --environment-id="${PUPPET_ENV}" --lifecycle-environment='DEV' --content-source-id="${CAPSULE_ID}" --puppet-proxy="$(hostname)" --puppet-ca-proxy="$(hostname)" --organization-id="${ORG}" --puppet-classes='access_insights_client,foreman_scap_client' --domain-id="${DOMAIN_ID}" --subnet="${SUBNET_NAME}" --architecture='x86_64' --operatingsystem-id="${RHEL6_OS_ID}" --partition-table='Kickstart default' --location-ids="${LOC}" --medium-id="${RHEL6_MEDIUM_ID}"

    satellite hostgroup set-parameter --hostgroup='RHEL 6 Server 64-bit HG' --name='kt_activation_keys' --value='ak-rhel-6'

    satellite hostgroup create --name='RHEL 7 Server 64-bit HG' --content-view='RHEL 7 CV' --environment-id="${PUPPET_ENV}" --lifecycle-environment='DEV' --content-source-id="${CAPSULE_ID}" --puppet-proxy="$(hostname)" --puppet-ca-proxy="$(hostname)" --organization-id="${ORG}" --puppet-classes='access_insights_client,foreman_scap_client' --domain-id="${DOMAIN_ID}" --subnet="${SUBNET_NAME}" --architecture='x86_64' --operatingsystem-id="${RHEL7_OS_ID}" --partition-table='Kickstart default' --location-ids="${LOC}" --medium-id="${RHEL7_MEDIUM_ID}"

    satellite hostgroup set-parameter --hostgroup='RHEL 7 Server 64-bit HG' --name='kt_activation_keys' --value='ak-rhel-7'
fi

# Provision a host with Libvirt Provider.
# Better create hosts from UI, as it has too many parameters to be passed and things appear to keep changing.
#satellite host create --name='rhel-7-libvirt' --root-pass='changeme' --organization-id="${ORG}" --location-id="${LOC}" --hostgroup="RHEL 7 Server 64-bit HG" --compute-resource="$COMPUTE_RESOURCE_NAME_LIBVIRT" --compute-attributes="cpus=1, memory=1073741824, start=1" --interface="primary=true, compute_type=bridge, compute_bridge=${SUBNET_NAME}, compute_model=virtio" --volume="capacity=10G,format_type=qcow2"

#satellite host create --name='rhel-6-libvirt' --root-pass='changeme' --organization-id="${ORG}" --location-id="${LOC}" --hostgroup="RHEL 6 Server 64-bit HG" --compute-resource="$COMPUTE_RESOURCE_NAME_LIBVIRT" --compute-attributes="cpus=1, memory=1073741824, start=1" --interface="primary=true, compute_type=bridge, compute_bridge=${SUBNET_NAME}, compute_model=virtio" --volume="capacity=10G,format_type=qcow2"
