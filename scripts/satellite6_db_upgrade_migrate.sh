pip install -U -r requirements.txt

# Set OS version for further use
export OS_VERSION="${OS#rhel}"

source ${CONFIG_FILES}
# Source the Variables from files
if [ -z "${SATELLITE_HOSTNAME}" ]; then
    source config/compute_resources.conf
    source config/sat6_upgrade.conf
fi
export SATELLITE_VERSION="${TO_VERSION}"
source config/sat6_repos_urls.conf
source config/subscription_config.conf


# Export required Environment variables for Downstream job
# As code in Automation Tools understands its Downstream :)
if [ "${DISTRIBUTION}" = 'DOWNSTREAM' ]; then
    export BASE_URL="${SATELLITE6_REPO}"
fi

# Customer DB Setup
if [ "${CUSTOMERDB_NAME}" != 'NoDB' ]; then
    source config/preupgrade_entities.conf
    if [ -n "${SATELLITE_HOSTNAME}" ]; then
        INSTANCE_NAME="${SATELLITE_HOSTNAME}"
    elif [ -z "${SATELLITE_HOSTNAME}" ]; then
        RHEV_INSTANCE_NAME="${CUSTOMERDB_NAME}_customerdb_instance"
        # Delete  if an instance with same name is already there in rhevm
        fab -u root delete_rhevm_instance:"${RHEV_INSTANCE_NAME}"
        # Create a RHEV instance of RHEL6/7 with given template, datacenter, quota and cluster
        fab -u root create_rhevm_instance:"${RHEV_INSTANCE_NAME}","custdb-${OS}-base",'SAT-QE','SAT-QE','SAT-QE'
        # To get the value of SAT_INSTANCE_FQDN variable
        source /tmp/rhev_instance.txt
        INSTANCE_NAME="${SAT_INSTANCE_FQDN}"
    fi
    # Clone the 'satellite-clone' w/ tag 1.0.1 that includes the ansible playbook to install sat server along with customer DB.
    git clone -b 1.1.1 --single-branch --depth 1 https://github.com/RedHatSatellite/satellite-clone.git
    pushd satellite-clone
    # Copy the satellite-clone-vars.sample.yml to satellite-clone-vars.yml
    cp -a satellite-clone-vars.sample.yml satellite-clone-vars.yml
    # Configuration Updates in inventory file
    sed -i -e 2s/.*/"${INSTANCE_NAME}"/ inventory
    # Define  Backup directory for customer DB 
    BACKUP_DIR="\/var\/tmp\/backup"
    # Prepare Customer DB URL
    if [ "${CUSTOMERDB_NAME}" = 'CentralCI' ]; then
        DB_URL="http://"${cust_db_server}"/customer-databases/Central-CI/6.2-OCT-13-2017/"
    elif [ "${CUSTOMERDB_NAME}" = 'ExpressScripts' ]; then
        DB_URL="http://"${cust_db_server}"/customer-databases/express-scripts/6.2-OCT-14-2017"
    elif [ "${CUSTOMERDB_NAME}" = 'Verizon' ]; then
        DB_URL="http://"${cust_db_server}"/customer-databases/Verizon/OCT-2-2017-62"
    elif [ "${CUSTOMERDB_NAME}" = 'Walmart' ]; then
        DB_URL="http://"${cust_db_server}"/customer-databases/walmart/6.2-OCT-2017"
    elif [ "${CUSTOMERDB_NAME}" = 'Sat62RHEL6Migrate' ]; then
        DB_URL="http://"${cust_db_server}"/customer-databases/qe-rhel6-db/sat62-rhel6-db"
    elif [ "${CUSTOMERDB_NAME}" = 'CustomDbURL' ]; then
        DB_URL="${CUSTOM_DB_URL}"
    fi
    # Configuration updates in vars file
    sed -i -e "s/^satellite_version.*/satellite_version: "${FROM_VERSION}"/" satellite-clone-vars.yml
    sed -i -e "s/^activationkey.*/activationkey: "test_ak"/" satellite-clone-vars.yml
    sed -i -e "s/^org.*/org: "Default\ Organization"/" satellite-clone-vars.yml
    sed -i -e "s/^#backup_dir.*/backup_dir: "${BACKUP_DIR}"/" satellite-clone-vars.yml
    sed -i -e "s/^#include_pulp_data.*/include_pulp_data: "${INCLUDE_PULP_DATA}"/" satellite-clone-vars.yml
    sed -i -e "s/^#restorecon.*/restorecon: "${RESTORECON}"/" satellite-clone-vars.yml
    # Note: Statements related to RHN_POOLID, RHN_PASSWORD, RHN_USERNAME and OS_VERSION added to support satellite6 upgrade through CDN
    # There are no such variables defined in satellite-clone-vars-sample.yaml
    sed -i -e "/org.*/arhn_pool: "${RHN_POOLID}"" satellite-clone-vars.yml
    sed -i -e "/org.*/arhn_password: "${RHN_PASSWORD}"" satellite-clone-vars.yml
    sed -i -e "/org.*/arhn_user: "${RHN_USERNAME}"" satellite-clone-vars.yml
    sed -i -e "/org.*/arhelversion: "${OS_VERSION}"" satellite-clone-vars.yml
    # Set the flag true in case of migrating the rhel6 satellite server to rhel7 machine
    if [ ${RHEL_MIGRATION} = "true" ]; then
        sed -i -e "s/^#rhel_migration.*/rhel_migration: "${RHEL_MIGRATION}"/" satellite-clone-vars.yml
        ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@"${INSTANCE_NAME}" "mkdir -p "${BACKUP_DIR}"; wget -q -P /var/tmp/backup -nd -r -l1 --no-parent -A '*.dump' "${DB_URL}""
        sed -i -e "s/^rhelversion.*/rhelversion: 7/" satellite-clone-vars.yml
    fi
    # Configuration updates in tasks file wrt vars file
    sed -i -e '/subscription-manager register.*/d' roles/satellite-clone/tasks/main.yml
    sed -i -e '/register host.*/a\ \ command: subscription-manager register --force --user={{ rhn_user }} --password={{ rhn_password }} --release={{ rhelversion }}Server' roles/satellite-clone/tasks/main.yml
    sed -i -e '/subscription-manager register.*/a- name: subscribe machine' roles/satellite-clone/tasks/main.yml
    sed -i -e '/subscribe machine.*/a\ \ command: subscription-manager subscribe --pool={{ rhn_pool }}' roles/satellite-clone/tasks/main.yml
    # Download the Customer DB data Backup files
    echo "Downloading Customer Data DB's from Server, This may take while depending on the network ....."
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@"${INSTANCE_NAME}" "mkdir -p "${BACKUP_DIR}"; wget -q -P /var/tmp/backup -nd -r -l1 --no-parent -A '*.tar*' "${DB_URL}"" 
    # Run Ansible command to install satellite with cust DB
    export ANSIBLE_HOST_KEY_CHECKING=False
    ansible all -i inventory -m ping -u root
    ansible-playbook -i inventory satellite-clone-playbook.yml
    # Return to the parent directory
    popd
fi

# Run satellite upgrade only when PERORM_UPGRADE flag is set.
if [ "${PERFORM_UPGRADE}" = "true" ]; then
    # Sets up the satellite, capsule and clients on rhevm or personal boxes before upgrading
    fab -u root setup_products_for_upgrade:"${UPGRADE_PRODUCT}","${OS}"
    # Run upgrade for CDN/Downstream
    fab -u root product_upgrade:"${UPGRADE_PRODUCT}"
    # Run existance tests
    if [ "${RUN_EXISTENCE_TESTS}" == 'true' ]; then
        $(which py.test) -v --junit-xml=test_existance-results.xml upgrade_tests/test_existance_relations/
    fi
    # Post Upgrade archive logs from log analyzer tool
    if [ -d upgrade-diff-logs ]; then
        tar -czf Log_Analyzer_Logs.tar.xz upgrade-diff-logs
    fi
fi

# Run satellite upgrade only when PERFORM_FOREMAN_MAINTAIN_UPGRADE flag is set
if [ "${PERFORM_FOREMAN_MAINTAIN_UPGRADE}" = "true" ]; then
    # setup foreman-maintain
    fab -u root@"${SATELLITE_HOSTNAME}" setup_foreman_maintain
    # perform upgrade using foreman-maintain
    fab -u root@"${SATELLITE_HOSTNAME}" upgrade_using_foreman_maintain
fi
