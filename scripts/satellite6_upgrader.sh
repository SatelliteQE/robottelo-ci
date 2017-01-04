pip install -U -r requirements.txt

# Set OS version for further use
if [ "${OS}" = 'rhel7' ]; then
    export OS_VERSION='7'
elif [ "${OS}" = 'rhel6' ]; then
    export OS_VERSION='6'
fi

source ${CONFIG_FILES}
# Source the Variables from files
if [ -z "${SATELLITE_HOSTNAME}" ]; then
    source config/rhev.conf
fi
export SATELLITE_VERSION="${TO_VERSION}"
source config/sat6_repos_urls.conf
source config/subscription_config.conf

# Set Capsule URL as per OS
if [ "${OS}" = 'rhel7' ]; then
    CAPSULE_URL="${CAPSULE_RHEL7}"
elif [ "${OS}" = 'rhel6' ]; then
    CAPSULE_URL="${CAPSULE_RHEL6}"
fi

# Export required Environment variables for Downstream job
# As code in Automation Tools understands its Downstream :)
if [ "${DISTRIBUTION}" = 'DOWNSTREAM' ]; then
    export BASE_URL="${SATELLITE6_REPO}"
    export CAPSULE_URL
    export TOOLS_URL_RHEL6="${TOOLS_RHEL6}"
    export TOOLS_URL_RHEL7="${TOOLS_RHEL7}"
fi

# Customer DB Setup
if [ ! -z "${CUSTOMER_SAT_HOSTNAME}" ]; then
    # Clone the 'satellite-clone' project that includes the ansible playbook to install sat server along with customer DB.
    git clone https://github.com/RedHatSatellite/satellite-clone.git
    source config/preupgrade_entities.conf
    pushd satellite-clone
    # Copy the inventory.sample to inventory
    cp -a inventory.sample inventory
    # Configuration Updates in inventory file
    sed -i -e 2s/.*/"${SATELLITE_HOSTNAME}"/ inventory
    # Copy the main.sample.yml to main.yml
    cp -a roles/sat6repro/vars/main.sample.yml roles/sat6repro/vars/main.yml
    # Configuration updates in vars file
    sed -i -e "s/^hostname.*/hostname: "${CUSTOMER_SAT_HOSTNAME}"/" roles/sat6repro/vars/main.yml
    sed -i -e "s/^rhelversion.*/rhelversion: $OS_VERSION/" roles/sat6repro/vars/main.yml
    sed -i -e "s/^satelliteversion.*/satelliteversion: "${FROM_VERSION}"/" roles/sat6repro/vars/main.yml
    sed -i -e "/org.*/arhn_pool: "${RHN_POOLID}"" roles/sat6repro/vars/main.yml
    sed -i -e "/org.*/arhn_password: "${RHN_PASSWORD}"" roles/sat6repro/vars/main.yml
    sed -i -e "/org.*/arhn_user: "${RHN_USERNAME}"" roles/sat6repro/vars/main.yml
    # Configuration updates in tasks file wrt vars file
    sed -i -e '/subscription-manager register.*/d' roles/sat6repro/tasks/main.yml
    sed -i -e '/subscribe the VM.*/a\ \ command: subscription-manager register --force --user={{ rhn_user }} --password={{ rhn_password }} --release={{ rhelversion }}Server' roles/sat6repro/tasks/main.yml
    sed -i -e '/subscription-manager register.*/a- name: subscribe machine' roles/sat6repro/tasks/main.yml
    sed -i -e '/subscribe machine.*/a\ \ command: subscription-manager subscribe --pool={{ rhn_pool }}' roles/sat6repro/tasks/main.yml
    if [[ "${FROM_VERSION}" = '6.1' && ! -z "${DHCP_INTERFACE}" ]]; then
        sed -i -e "s/katello-installer.*/katello-installer --capsule-dhcp-interface "${DHCP_INTERFACE}"/" roles/sat6repro/tasks/main.yml
    fi
    # Download the Customer DB data Backup files
    echo "Copying Customer Data DB's from Server, This may take while depending on the network ....."
    scp root@"${cust_db_server}":/customer-databases/"${CUSTOMER_NAME}"/* roles/sat6repro/files/
    # Renaming the data backup files as we need
    mv roles/sat6repro/files/*conf* roles/sat6repro/files/config_files.tar.gz | echo
    mv roles/sat6repro/files/*pg* roles/sat6repro/files/pgsql_data.tar.gz | echo
    mv roles/sat6repro/files/*mongo* roles/sat6repro/files/mongo_data.tar.gz | echo
    # Run Ansible command to install satellite with cust DB
    export ANSIBLE_HOST_KEY_CHECKING=False
    ansible all -i inventory -m ping -u root
    ansible-playbook -i inventory satellite-clone-playbook.yml
    # Return to the parent directory
    popd
fi

# Run upgrade for CDN/Downstream
fab -u root product_upgrade:"${UPGRADE_PRODUCT}"
