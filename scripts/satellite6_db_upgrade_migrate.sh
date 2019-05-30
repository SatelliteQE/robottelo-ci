pip install -U -r requirements.txt
pip install -r requirements-optional.txt

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

export PYTEST_OPTIONS="tests/foreman/cli/test_activationkey.py tests/foreman/cli/test_contentview.py tests/foreman/cli/test_repository.py tests/foreman/cli/test_product.py"
# Export required Environment variables for Downstream job
# As code in Automation Tools understands its Downstream :)
if [ "${DISTRIBUTION}" = 'DOWNSTREAM' ]; then
    export BASE_URL="${SATELLITE6_REPO}"
fi

if [[ -z "${SATELLITE_HOSTNAME}" && "${OPENSTACK_DEPLOY}" = 'true' ]]; then
    source config/preupgrade_entities.conf
    fab -D -u root delete_openstack_instance:"customerdb_${CUSTOMERDB_NAME}"
    fab -D -u root create_openstack_instance:"customerdb_${CUSTOMERDB_NAME}","${RHEL7_IMAGE}","${VOLUME_SIZE}"
fi

# Customer DB Setup
if [ "${CUSTOMERDB_NAME}" != 'NoDB' ]; then
    source config/preupgrade_entities.conf
    if [ -n "${SATELLITE_HOSTNAME}" ]; then
        INSTANCE_NAME="${SATELLITE_HOSTNAME}"
    elif [[ -z "${SATELLITE_HOSTNAME}" && -z "${OPENSTACK_DEPLOY}" ]]; then
        RHEV_INSTANCE_NAME="${CUSTOMERDB_NAME}_customerdb_instance"
        # Delete  if an instance with same name is already there in rhevm
        fab -u root delete_rhevm_instance:"${RHEV_INSTANCE_NAME}"
        # Create a RHEV instance of RHEL6/7 with given template, datacenter, quota and cluster
        fab -u root create_rhevm_instance:"${RHEV_INSTANCE_NAME}","custdb-${OS}-base",'SAT-QE','SAT-QE','SAT-QE'
        # To get the value of SAT_INSTANCE_FQDN variable
        source /tmp/rhev_instance.txt
        INSTANCE_NAME="${SAT_INSTANCE_FQDN}"
    fi
    # Clone the 'satellite-clone' w/ tag 1.1.1/master that includes the ansible playbook to install sat server along with customer DB.
    git clone -b master --single-branch --depth 1 https://github.com/RedHatSatellite/satellite-clone.git
    pushd satellite-clone
    # Copy the satellite-clone-vars.sample.yml to satellite-clone-vars.yml
    cp -a satellite-clone-vars.sample.yml satellite-clone-vars.yml
    # Define  Backup directory for customer DB
    BACKUP_DIR="\/var\/tmp\/backup"
    if [[ -z "${SATELLITE_HOSTNAME}" && "${OPENSTACK_DEPLOY}" = 'true' ]]; then
        source /tmp/instance.info
        INSTANCE_NAME="${OSP_HOSTNAME}"
        BACKUP_DIR="\/tmp\/customer-dbs\/${CUSTOMERDB_NAME}"
        # Install Nfs-client
        # Mount the Customer DB to Created Instance via NFS Share
        ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@"${INSTANCE_NAME}" "curl -o /etc/yum.repos.d/rhel.repo "${RHEL_REPO}"; yum install -y nfs-utils; mkdir -p /tmp/customer-dbs; mount -o v3 "${DBSERVER}":/root/customer-dbs /tmp/customer-dbs"
    fi
    export SATELLITE_HOSTNAME="${INSTANCE_NAME}"
    if [ "${PARTITION_DISK}" = "true" ]; then
        fab -D -H root@"${INSTANCE_NAME}" partition_disk
    fi
    # Configuration Updates in inventory file
    sed -i -e 2s/.*/"${INSTANCE_NAME}"/ inventory
    # Prepare Customer DB URL
    if [ "${CUSTOMERDB_NAME}" = 'CentralCI' ]; then
        DB_URL="http://"${cust_db_server}"/customer-databases/Central-CI/6.2-OCT-13-2017/"
    elif [ "${CUSTOMERDB_NAME}" = 'ExpressScripts' ]; then
        DB_URL="http://"${cust_db_server}"/customer-databases/express-scripts/6.2-OCT-14-2017"
    elif [ "${CUSTOMERDB_NAME}" = 'Verizon' ]; then
        DB_URL="http://"${cust_db_server}"/customer-databases/Verizon/OCT-2-2017-62"
    elif [ "${CUSTOMERDB_NAME}" = 'Walmart' ]; then
        DB_URL="http://"${cust_db_server}"/customer-databases/walmart/6.2-OCT-2017"
    elif [ "${CUSTOMERDB_NAME}" = 'CreditSuisse' ]; then
        DB_URL="http://"${cust_db_server}"/customer-databases2/credit-suisse/MAY-21-2018-631/"
    elif [ "${CUSTOMERDB_NAME}" = 'ATPC' ]; then
        DB_URL="http://"${cust_db_server}"/customer-databases2/ATPC/JUN-16-2018-631/"
    elif [ "${CUSTOMERDB_NAME}" = 'Sat62RHEL6Migrate' ]; then
        DB_URL="http://"${cust_db_server}"/customer-databases/qe-rhel6-db/sat62-rhel6-db"
    elif [ "${CUSTOMERDB_NAME}" = 'CustomDbURL' ]; then
        DB_URL="${CUSTOM_DB_URL}"
    fi
    if [ "${USE_CLONE_RPM}" != 'true' ]; then
        # Configuration updates in vars file
        if [ "${FROM_VERSION}" == "6.2" ]; then
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
        else
            echo "satellite_version: "${FROM_VERSION}"" >> satellite-clone-vars.yml
            echo "activationkey: "test_ak"" >> satellite-clone-vars.yml
            echo "org: "Default Organization"" >> satellite-clone-vars.yml
            sed -i -e "s/^#backup_dir.*/backup_dir: "${BACKUP_DIR}"/" satellite-clone-vars.yml
            echo "include_pulp_data: "${INCLUDE_PULP_DATA}"" >> satellite-clone-vars.yml
            echo "restorecon: "${RESTORECON}"" >> satellite-clone-vars.yml
            echo "register_to_portal: true" >> satellite-clone-vars.yml
            sed -i -e "/#org.*/arhn_pool: "$(echo ${RHN_POOLID} | cut -d' ' -f1)"" satellite-clone-vars.yml
            sed -i -e "/#org.*/arhn_password: "${RHN_PASSWORD}"" satellite-clone-vars.yml
            sed -i -e "/#org.*/arhn_user: "${RHN_USERNAME}"" satellite-clone-vars.yml
            sed -i -e "/#org.*/arhelversion: "${OS_VERSION}"" satellite-clone-vars.yml
        fi
    else
        fab -H root@"${SATELLITE_HOSTNAME}" setup_satellite_clone
        export CLONE_DIR="/usr/share/satellite-clone/satellite-clone-vars.yml"
        ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@"${SATELLITE_HOSTNAME}" << EOF
        echo "satellite_version: "${FROM_VERSION}"" >> "${CLONE_DIR}"
        echo "activationkey: "test_ak"" >> "${CLONE_DIR}"
        echo "org: "Default Organization"" >> "${CLONE_DIR}"
        sed -i -e "/#backup_dir.*/abackup_dir: "${BACKUP_DIR}"/" "${CLONE_DIR}"
        echo "include_pulp_data: "${INCLUDE_PULP_DATA}"" >> "${CLONE_DIR}"
        echo "restorecon: "${RESTORECON}"" >> "${CLONE_DIR}"
        echo "register_to_portal: true" >> "${CLONE_DIR}"
        sed -i -e "/#org.*/arhn_pool: "$(echo ${RHN_POOLID} | cut -d' ' -f1)"" "${CLONE_DIR}"
        sed -i -e "/#org.*/arhn_password: "${RHN_PASSWORD}"" "${CLONE_DIR}"
        sed -i -e "/#org.*/arhn_user: "${RHN_USERNAME}"" "${CLONE_DIR}"
        sed -i -e "/#org.*/arhelversion: "${OS_VERSION}"" "${CLONE_DIR}"
EOF
    fi
    # Set the flag true in case of migrating the rhel6 satellite server to rhel7 machine
    if [ ${RHEL_MIGRATION} = "true" ]; then
        ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@"${INSTANCE_NAME}" "mkdir -p "${BACKUP_DIR}"; wget -q -P /var/tmp/backup -nd -r -l1 --no-parent -A '*.dump' "${DB_URL}""
        if [ "${USE_CLONE_RPM}" != 'true' ]; then
            sed -i -e "s/^#rhel_migration.*/rhel_migration: "${RHEL_MIGRATION}"/" satellite-clone-vars.yml
            sed -i -e "s/^rhelversion.*/rhelversion: 7/" satellite-clone-vars.yml
        else
            ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@"${SATELLITE_HOSTNAME}" << EOF
            sed -i -e "s/^#rhel_migration.*/rhel_migration: "${RHEL_MIGRATION}"/" "${CLONE_DIR}"
            sed -i -e "s/^rhelversion.*/rhelversion: 7/" "${CLONE_DIR}"
EOF
        fi
    fi
    if [ "${USE_CLONE_RPM}" != 'true' ]; then
        # Configuration updates in tasks file wrt vars file
        sed -i -e '/subscription-manager register.*/d' roles/satellite-clone/tasks/main.yml
        if [ "${FROM_VERSION}" == "6.2" ]; then
            sed -i -e '/register host.*/a\ \ command: subscription-manager register --force --user={{ rhn_user }} --password={{ rhn_password }} --release={{ rhelversion }}Server' roles/satellite-clone/tasks/main.yml
        else
            sed -i -e '/Register\/Subscribe the system to Red Hat Portal.*/a\ \ command: subscription-manager register --force --user={{ rhn_user }} --password={{ rhn_password }} --release={{ rhelversion }}Server' roles/satellite-clone/tasks/main.yml
        fi
        sed -i -e '/subscription-manager register.*/a- name: subscribe machine' roles/satellite-clone/tasks/main.yml
        sed -i -e '/subscribe machine.*/a\ \ command: subscription-manager subscribe --pool={{ rhn_pool }}' roles/satellite-clone/tasks/main.yml
    else
        export MAIN_YAML="/usr/share/satellite-clone/roles/satellite-clone/tasks/main.yml"
        ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@"${SATELLITE_HOSTNAME}" << EOF
        sed -i -e '/subscription-manager register.*/d' "${MAIN_YAML}"
        sed -i -e '/Register\/Subscribe the system to Red Hat Portal.*/a\ \ command: subscription-manager register --force --user={{ rhn_user }} --password={{ rhn_password }} --release={{ rhelversion }}Server' "${MAIN_YAML}"
        sed -i -e '/subscription-manager register.*/a- name: subscribe machine' "${MAIN_YAML}"
        sed -i -e '/subscribe machine.*/a\ \ command: subscription-manager subscribe --pool={{ rhn_pool }}' "${MAIN_YAML}"

EOF
    fi
    # Download the Customer DB data Backup files
    echo "Downloading Customer Data DB's from Server, This may take while depending on the network ....."
    if [ "${OPENSTACK_DEPLOY}" != 'true' ]; then
        ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@"${INSTANCE_NAME}" "mkdir -p "${BACKUP_DIR}"; wget -q -P /var/tmp/backup -nd -r -l1 --no-parent -A '*.tar*' "${DB_URL}""
        ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@"${INSTANCE_NAME}" "wget -q -P /var/tmp/backup -nd -r -l1 --no-parent -A '*metadata*' "${DB_URL}""
    fi
    if [ "${USE_CLONE_RPM}" != 'true' ]; then
        # Run Ansible command to install satellite with cust DB
        export ANSIBLE_HOST_KEY_CHECKING=False
        ansible all -i inventory -m ping -u root
        ansible-playbook -i inventory satellite-clone-playbook.yml
        # Return to the parent directory
        popd
    else
        ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@"${SATELLITE_HOSTNAME}" "satellite-clone -y"
    fi
fi

if [ "${PUPPET4_UPGRADE}" = "true" ]; then
    # perform puppet3 to puppet4 upgrade
    fab -H root@"${SATELLITE_HOSTNAME}" upgrade_puppet3_to_puppet4
fi

# Run satellite upgrade only when PERORM_UPGRADE flag is set.
if [ "${PERFORM_UPGRADE}" = "true" ]; then
    # Sets up the satellite, capsule and clients on rhevm or personal boxes before upgrading
    fab -u root setup_products_for_upgrade:"${UPGRADE_PRODUCT}","${OS}"
    # Run upgrade for CDN/Downstream
    fab -u root product_upgrade:"${UPGRADE_PRODUCT}"
    # Run existance tests
    if [ "${RUN_EXISTENCE_TESTS}" == 'true' ]; then
        $(which py.test) -v --junit-xml=test_existance-results.xml -o junit_suite_name=test_existance upgrade_tests/test_existance_relations/
    fi
    # Post Upgrade archive logs from log analyzer tool
    if [ -d upgrade-diff-logs ]; then
        tar -czf Log_Analyzer_Logs.tar.xz upgrade-diff-logs
    fi
fi
