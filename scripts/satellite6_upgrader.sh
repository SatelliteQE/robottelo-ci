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
    source config/compute_resources.conf
    source config/sat6_upgrade.conf
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
if [ "${CUSTOMERDB_NAME}" != 'None' ]; then
    source config/preupgrade_entities.conf
    INSTANCE_NAME="${CUSTOMERDB_NAME}_customerdb_instance"
    # Delete  if an instance with same name is already there in rhevm
    fab -u root delete_rhevm_instance:"${INSTANCE_NAME}"
    # Create a RHEV instance of RHEL6/7 with given template, datacenter, quota and cluster
    fab -u root create_rhevm_instance:"${INSTANCE_NAME}","custdb-${OS}-base",'SAT-QE','SAT-QE','SAT-QE'
    # To get the value of SAT_INSTANCE_FQDN variable
    source /tmp/rhev_instance.txt
    # Clone the 'satellite-clone' project that includes the ansible playbook to install sat server along with customer DB.
    git clone -b satellite-clone-1.0 https://github.com/RedHatSatellite/satellite-clone.git
    pushd satellite-clone
    # Copy the inventory.sample to inventory
    cp -a inventory.sample inventory
    # Configuration Updates in inventory file
    sed -i -e 2s/.*/"${SAT_INSTANCE_FQDN}"/ inventory
    # Copy the main.sample.yml to main.yml
    cp -a roles/sat6repro/vars/main.sample.yml roles/sat6repro/vars/main.yml
    # Define  Backup directory for customer DB 
    BACKUP_DIR="\/var\/tmp\/backup"
    # Configuration updates in vars file
    sed -i -e "s/^rhelversion.*/rhelversion: $OS_VERSION/" roles/sat6repro/vars/main.yml
    sed -i -e "s/^satelliteversion.*/satelliteversion: "${FROM_VERSION}"/" roles/sat6repro/vars/main.yml
    sed -i -e "s/^backup_dir.*/backup_dir: $BACKUP_DIR/" roles/sat6repro/vars/main.yml
    sed -i -e "s/^include_pulp_data.*/include_pulp_data: false/" roles/sat6repro/vars/main.yml
    sed -i -e "/org.*/arhn_pool: "${RHN_POOLID}"" roles/sat6repro/vars/main.yml
    sed -i -e "/org.*/arhn_password: "${RHN_PASSWORD}"" roles/sat6repro/vars/main.yml
    sed -i -e "/org.*/arhn_user: "${RHN_USERNAME}"" roles/sat6repro/vars/main.yml
    # Configuration updates in tasks file wrt vars file
    sed -i -e '/subscription-manager register.*/d' roles/sat6repro/tasks/main.yml
    sed -i -e '/register host.*/a\ \ command: subscription-manager register --force --user={{ rhn_user }} --password={{ rhn_password }} --release={{ rhelversion }}Server' roles/sat6repro/tasks/main.yml
    sed -i -e '/subscription-manager register.*/a- name: subscribe machine' roles/sat6repro/tasks/main.yml
    sed -i -e '/subscribe machine.*/a\ \ command: subscription-manager subscribe --pool={{ rhn_pool }}' roles/sat6repro/tasks/main.yml
    # Prepare Customer DB URL
    if [ "${CUSTOMERDB_NAME}" = 'Lidl' ]; then
        DB_URL="http://"${cust_db_server}"/pub/customer-databases/lidl"
    elif [ "${CUSTOMERDB_NAME}" = 'ExpressScripts' ]; then
        DB_URL="http://"${cust_db_server}"/pub/customer-databases/express-scripts/6.2-NOV-28-2016"
    fi
    # Download the Customer DB data Backup files
    echo "Downloading Customer Data DB's from Server, This may take while depending on the network ....."
    ssh -o "StrictHostKeyChecking no" root@"${SAT_INSTANCE_FQDN}" "mkdir -p "${BACKUP_DIR}"; wget -q -P /var/tmp/backup -nd -r -l1 --no-parent -A '*.tar.gz' "${DB_URL}"" 
    # Update the hostname as per Customer DB
    CUSTOMER_SAT_HOSTNAME="$(ssh -o 'StrictHostKeyChecking no' root@"${SAT_INSTANCE_FQDN}" "tar -zxf "${BACKUP_DIR}"/config_files.tar.gz etc/httpd/conf/httpd.conf -O" | grep ServerName | awk -F'"' '{print $2}')"
    sed -i -e "s/^hostname.*/hostname: "${CUSTOMER_SAT_HOSTNAME}"/" roles/sat6repro/vars/main.yml
    # Run Ansible command to install satellite with cust DB
    export ANSIBLE_HOST_KEY_CHECKING=False
    ansible all -i inventory -m ping -u root
    ansible-playbook -i inventory satellite-clone-playbook.yml
    # Return to the parent directory
    popd
fi

# Run upgrade for CDN/Downstream
fab -u root product_upgrade:"${UPGRADE_PRODUCT}"

# Post Upgrade archive logs from log analyzer tool
if [ -d upgrade-diff-logs ]; then
    tar -czf Log_Analyzer_Logs.tar.xz upgrade-diff-logs
fi
