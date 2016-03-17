pip install -U -r requirements.txt

# Set OS version for further use
if [ "${OS}" = 'rhel7' ]; then
        export OS_VERSION='7'
elif [ "${OS}" = 'rhel6' ]; then
        export OS_VERSION='6'
fi

# Source the Variables from files
source "${RHEV_CONFIG}"
source "${SATELLITE6_REPOS_URLS}"
source "${SUBSCRIPTION_CONFIG}"

if [ -n "${SATELLITE_HOSTNAME}" ]; then
	if [ "${DISTRIBUTION}" = 'CDN' ]; then
		# Run upgrade without compose urls
		fab -u root product_upgrade:"${UPGRADE_PRODUCT}"
	elif [ "${DISTRIBUTION}" = 'DOWNSTREAM' ]; then
		# Export required Environment variables
		export BASE_URL="${SATELLITE6_REPO}"
		export CAPSULE_URL="${CAPSULE_REPO}"
		# Run upgrade with above compose urls
		fab -u root product_upgrade:"${UPGRADE_PRODUCT}"
	fi
elif [ -n "${SATELLITE_IMAGE}" ]; then
	if [ "${DISTRIBUTION}" = 'CDN' ]; then
		# Run upgrade without compose urls
		fab -u root product_upgrade:"${UPGRADE_PRODUCT}","${SATELLITE_IMAGE}","${CAPSULE_IMAGE}"
	elif [ "${DISTRIBUTION}" = 'DOWNSTREAM' ]; then
		# Export required Environment variables
		export BASE_URL="${SATELLITE6_REPO}"
		export CAPSULE_URL="${CAPSULE_REPO}"
		# Run upgrade with above compose urls
		fab -u root product_upgrade:"${UPGRADE_PRODUCT}","${SATELLITE_IMAGE}","${CAPSULE_IMAGE}"
	fi
fi
