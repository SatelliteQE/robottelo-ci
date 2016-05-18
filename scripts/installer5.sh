pip install -U pip

if [ "$(curl --version | grep NSS 2>/dev/null)" ]; then
    pip install --compile --install-option="--with-nss" pycurl
else
    pip install --compile --install-option="--with-openssl" pycurl
fi

pip install -U -r requirements.txt

source ${SUBSCRIPTION_CONFIG}
source ${SAT5_CERT_CONFIG}

if [ ${FIX_HOSTNAME} = "true" ]; then
    fab -H root@${SERVER_HOSTNAME} fix_hostname
fi

if [ ${PARTITION_DISK} = "true" ]; then
    fab -H root@${SERVER_HOSTNAME} partition_disk
fi

# Figure out what version of RHEL the server uses
OS_VERSION=$(fab -H root@${SERVER_HOSTNAME} distro_info | grep "rhel [[:digit:]]" | cut -d ' ' -f 2)
# export chosen Jenkins job parameters for usage by fabric
export RHN_PROFILE="robottelo_${SERVER_HOSTNAME}"

if [ ${DISTRIBUTION} = "RELEASED" ]; then
    export ISO_URL="http://download/released/Satellite-${SAT5_VERSION}-RHEL-${OS_VERSION}/x86_64/ftp-isos/"
fi

if [ ${DISTRIBUTION} = "CANDIDATE" ]; then
    export ISO_URL="http://download/devel/candidates/latest-link-Satellite-5.7.0-RHEL${OS_VERSION}-x86_64/iso/"
fi

fab -H root@${SERVER_HOSTNAME} satellite5_product_install
