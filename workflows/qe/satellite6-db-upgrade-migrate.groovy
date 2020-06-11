@Library("github.com/SatelliteQE/robottelo-ci") _

pipeline {
    agent { label 'sat6-rhel7' }

    environment {
        PYTEST_OPTIONS = "tests/foreman/cli/test_activationkey.py tests/foreman/cli/test_contentview.py tests/foreman/cli/test_repository.py tests/foreman/cli/test_product.py"
        CLONE_DIR = "/usr/share/satellite-clone/satellite-clone-vars.yml"
   }
    stages {
        stage('Setup environment') {
            steps {
                workspace_cleanup()
                make_venv python: defaults.python
                git branch: branch_selection("${params.TO_VERSION}"), url: defaults.satellite6_upgrade
                sh_venv '''
                    export PYCURL_SSL_LIBRARY=\$(curl -V | sed -n 's/.*\\(NSS\\|OpenSSL\\).*/\\L\\1/p')
                    pip install -U -r requirements.txt
                    pip install -r requirements-optional.txt
                '''
                }
            }
        stage('Install requirements') {
            steps {
                loading_the_groovy_script_to_build_db_environment()
                }
        }
        stage("DB Upgrade Setup"){
            steps {
                ansiColor('xterm') {
                    instance_creation_deletion()
                    customer_db_setup()
                    build_display_name()
                    inventory_configuration()
                    satellite_clone_setup()
                    check_the_flag_incase_of_migration()
                    setting_CloneRPM()
                }
            }
        }
        stage ("Download Customer DB Backup")
        {
            steps{
                ansiColor('xterm') {
                    download_customerDB_Backup()
                }
            }
        }
        stage ("Restart Upgrade"){
            when {
                isRestartedRun()
            }
            steps{
                loading_the_groovy_script_to_build_db_environment()
                build_display_name()
            }
        }
        stage("Upgrade"){
            steps{
                ansiColor('xterm') {
                    setup_for_existence_test()
                    workaround()
                    perform_upgrade()
                    setup_for_existence_test()
                    existence_test_execution()
                    mongodb_upgrade()
                    satellite_backup()
                }
            }
        }
    }
    post {
        always{
            mail_notification()
            post_upgrade_result()
        }
    }
 }


def conditional_param_execution(args){
    env.DISTRO = env.OS
    if (args.param.size() == 0){
        load('config/compute_resources.groovy')
        load('config/sat6_upgrade.groovy')
        environment_variable_for_sat6_upgrade()
        environment_variable_for_compute_resource()
    }
    env.SATELLITE_VERSION = env.TO_VERSION
    env.SATELLITE_HOSTNAME = env.SATELLITE_HOSTNAME == null?'':env.SATELLITE_HOSTNAME
}


def instance_creation_deletion(){
    if (env.SATELLITE_HOSTNAME.size() == 0 && env.OPENSTACK_DEPLOY == 'true'){
        load('config/preupgrade_entities.groovy')
        environment_variable_for_preupgrade()
        load('config/customers_name.groovy')
        environment_variable_for_DB()
        sh_venv '''fab -D -u root delete_openstack_instance:"customerdb_"${CUSTOMERDB_NAME}
                   fab -D -u root create_openstack_instance:"customerdb_"${CUSTOMERDB_NAME},"${RHEL7_IMAGE}","${VOLUME_SIZE}"'''
    }
}


def customer_db_setup(){
    if (env.CUSTOMERDB_NAME != "NoDB"){
        load('config/preupgrade_entities.groovy')
        environment_variable_for_preupgrade()
        if (env.SATELLITE_HOSTNAME){
            env.INSTANCE_NAME = env.SATELLITE_HOSTNAME
        }
        else if (! env.SATELLITE_HOSTNAME && env.OPENSTACK_DEPLOY != 'true') {
            def RHEV_INSTANCE_NAME = env.CUSTOMERDB_NAME + "_customerdb_instance"
            env.RHEV_INSTANCE_NAME = RHEV_INSTANCE_NAME
            sh_venv '''fab -u root delete_rhevm_instance:"${RHEV_INSTANCE_NAME}
                fab -u root create_rhevm_instance:"${RHEV_INSTANCE_NAME}
                source /tmp/rhev_instance.txt'''
            env.INSTANCE_NAME = env.SAT_INSTANCE_FQDN
        }
        sh_venv '''if [ -d  satellite-clone ]; then rm -rf satellite-clone ;fi'''
        checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'satellite-clone']], submoduleCfg: [], userRemoteConfigs: [[url: defaults.satellite6_clone]]])
        dir('satellite-clone') {
            make_venv python: defaults.python
            sh_venv '''
                    cp -r ../README.md ../setup.py .
                    export PYCURL_SSL_LIBRARY=\$(curl -V | sed -n 's/.*\\(NSS\\|OpenSSL\\).*/\\L\\1/p')
                    pip install -U -r ../requirements.txt
                    pip install -r ../requirements-optional.txt
                    cp -a satellite-clone-vars.sample.yml satellite-clone-vars.yml
            '''
        }
        env.BACKUP_DIR = "\\/var\\/tmp\\/backup"
        def repo_setup = ! env.SATELLITE_HOSTNAME && env.OPENSTACK_DEPLOY == 'true'?openstack_deploy():''
        env.SATELLITE_HOSTNAME = env.INSTANCE_NAME
        if (env.PARTITION_DISK) {
            sh_venv '''fab -D -H root@${INSTANCE_NAME} partition_disk'''
        }
    }
}


def openstack_deploy(){
    env.BACKUP_DIR = "\\/tmp\\/customer-dbs\\/${env.CUSTOMERDB_NAME}"
    /// Need to check environment set on ssh_evenv
    def INSTANCE_NAME = sh(script: 'source /tmp/instance.info; echo ${OSP_HOSTNAME} ',returnStdout: true).trim()
    env.INSTANCE_NAME = INSTANCE_NAME
    sh_venv '''
        ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${INSTANCE_NAME} "curl -o /etc/yum.repos.d/rhel.repo "${RHEL_REPO}"; yum install -y nfs-utils; mkdir -p /tmp/customer-dbs; mount -o v3 "${DBSERVER}":/root/customer-dbs /tmp/customer-dbs"'''
}


def inventory_configuration(){
    //cust_db_server variable is loaded as groovy variable
    dir('satellite-clone') {
        // make_venv python: defaults.python
        sh_venv '''sed -i -e 2s/.*/"${INSTANCE_NAME}"/ inventory'''
    }
}


def satellite_clone_setup() {
    if (env.USE_CLONE_RPM == 'true'){
        use_clone_rpm()
    }
    else {
        if (env.CLONE_WITH_LATEST_FOREMAN_MAINTAIN_PACKAGE == 'true') {
            sh_venv '''fab -H root@"${SATELLITE_HOSTNAME}" setup_foreman_maintain'''
        }
        satellite_clone_with_upstream()
    }
}


def satellite_clone_with_upstream(){
    if (env.FROM_VERSION == "6.2"){
        dir('satellite-clone') {
         sh_venv '''sed -i -e "s/^satellite_version.*/satellite_version: "${FROM_VERSION}"/" satellite-clone-vars.yml
                   sed -i -e "s/^activationkey.*/activationkey: "test_ak"/" satellite-clone-vars.yml
                   sed -i -e "s/^org.*/org: "Default\\ Organization"/" satellite-clone-vars.yml
                   sed -i -e "s/^#backup_dir.*/backup_dir: "${BACKUP_DIR}"/" satellite-clone-vars.yml
                   sed -i -e "s/^#include_pulp_data.*/include_pulp_data: "${INCLUDE_PULP_DATA}"/" satellite-clone-vars.yml
                   sed -i -e "s/^#restorecon.*/restorecon: "${RESTORECON}"/" satellite-clone-vars.yml
                   sed -i -e "/org.*/arhn_pool: "${RHN_POOLID}"" satellite-clone-vars.yml
                   sed -i -e "/org.*/arhn_password: "${RHN_PASSWORD}"" satellite-clone-vars.yml
                   sed -i -e "/org.*/arhn_user: "${RHN_USERNAME}"" satellite-clone-vars.yml
                   sed -i -e "/org.*/arhelversion: "${OS_VERSION}"" satellite-clone-vars.yml
            '''
        }
    }
    else {
        dir('satellite-clone') {
            sh_venv '''echo "satellite_version: "${FROM_VERSION}"" >> satellite-clone-vars.yml
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
                    '''
        }
    }
}


def use_clone_rpm(){
    dir('satellite-clone') {
        sh_venv '''
            fab -H root@"${SATELLITE_HOSTNAME}" setup_satellite_clone
            ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@"${SATELLITE_HOSTNAME}" << EOF
            echo "satellite_version: "$FROM_VERSION"" >> "$CLONE_DIR"
            echo "activationkey: "test_ak"" >> "$CLONE_DIR"
            echo "org: "Default Organization"" >> "$CLONE_DIR"
            sed -i -e "/#backup_dir.*/abackup_dir: "$BACKUP_DIR"/" "$CLONE_DIR"
            echo "include_pulp_data: "$INCLUDE_PULP_DATA"" >> "$CLONE_DIR"
            echo "restorecon: "$RESTORECON"" >> "$CLONE_DIR"
            echo "register_to_portal: true" >> "$CLONE_DIR"
            sed -i -e "/#org.*/arhn_pool: "$(echo $RHN_POOLID | cut -d' ' -f1)"" "$CLONE_DIR"
            sed -i -e "/#org.*/arhn_password: "$RHN_PASSWORD"" "$CLONE_DIR"
            sed -i -e "/#org.*/arhn_user: "$RHN_USERNAME"" "$CLONE_DIR"
            sed -i -e "/#org.*/arhelversion: "$OS_VERSION"" "$CLONE_DIR"
        EOF'''.stripIndent()
    }
}


def check_the_flag_incase_of_migration(){
    if (env.RHEL_MIGRATION == 'true') {
        //Set the flag true in case of migrating the rhel6 satellite server to rhel7 machine
        sh_venv ''' ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@"${INSTANCE_NAME}" "mkdir -p "${BACKUP_DIR}"; wget -q -P /var/tmp/backup -nd -r -l1 --no-parent -A '*.dump' "${DB_URL}"" '''
        if (env.USE_CLONE_RPM != 'true'){
            dir('satellite-clone') {
            sh_venv ''' sed -i -e "s/^#rhel_migration.*/rhel_migration: "${RHEL_MIGRATION}"/" satellite-clone-vars.yml
                sed -i -e "s/^rhelversion.*/rhelversion: 7/" satellite-clone-vars.yml '''
            }
        }
        else {
            dir('satellite-clone') {
                sh_venv '''
                    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@"${SATELLITE_HOSTNAME}" << EOF
                    sed -i -e "s/^#rhel_migration.*/rhel_migration: "$RHEL_MIGRATION"/" "$CLONE_DIR"
                    sed -i -e "s/^rhelversion.*/rhelversion: 7/" "$CLONE_DIR"
                 EOF'''.stripIndent()
            }
        }
    }
}


def setting_CloneRPM(){
    if (env.USE_CLONE_RPM != 'true') {
        dir('satellite-clone') {
            sh_venv ''' sed -i -e '/subscription-manager register.*/d' roles/satellite-clone/tasks/main.yml'''
            if (env.FROM_VERSION=="6.2"){
                sh_venv '''sed -i -e '/register host.*/a\\ \\ command: subscription-manager register --force --user={{ rhn_user }} --password={{ rhn_password }} --release={{ rhelversion }}Server' roles/satellite-clone/tasks/main.yml'''
            }
            else {
                sh_venv '''sed -i -e '/Register\\/Subscribe the system to Red Hat Portal.*/a\\ \\ command: subscription-manager register --force --user={{ rhn_user }} --password={{ rhn_password }} --release={{ rhelversion }}Server' roles/satellite-clone/tasks/main.yml'''
            }
            sh_venv ''' sed -i -e '/subscription-manager register.*/a- name: subscribe machine' roles/satellite-clone/tasks/main.yml
                        sed -i -e '/subscribe machine.*/a\\ \\ command: subscription-manager subscribe --pool={{ rhn_pool }}' roles/satellite-clone/tasks/main.yml '''
        }
    }
    else{
        dir('satellite-clone') {
            env.MAIN_YAML = "/usr/share/satellite-clone/roles/satellite-clone/tasks/main.yml"
            sh_venv '''
                ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@"${SATELLITE_HOSTNAME}" << EOF
                sed -i -e '/subscription-manager register.*/d' "$MAIN_YAML"
                sed -i -e '/Register\\/Subscribe the system to Red Hat Portal.*/a\\ \\ command: subscription-manager register --force --user={{ rhn_user }} --password={{ rhn_password }} --release={{ rhelversion }}Server' "$MAIN_YAML"
                sed -i -e '/subscription-manager register.*/a- name: subscribe machine' "$MAIN_YAML"
                sed -i -e '/subscribe machine.*/a\\ \\ command: subscription-manager subscribe --pool={{ rhn_pool }}' "$MAIN_YAML"
        EOF'''.stripIndent()
        }
    }
}


def download_customerDB_Backup(){
    dir('satellite-clone') {
        if (env.OPENSTACK_DEPLOY != 'true') {
            sh_venv '''ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@"${INSTANCE_NAME}" "mkdir -p "${BACKUP_DIR}"; wget -q -P /var/tmp/backup -nd -r -l1 --no-parent -A '*.tar*' "${DB_URL}""
                ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@"${INSTANCE_NAME}" "wget -q -P /var/tmp/backup -nd -r -l1 --no-parent -A '*metadata*' "${DB_URL}"" '''
        }
        if (USE_CLONE_RPM != 'true'){
            env.ANSIBLE_HOST_KEY_CHECKING = false
            sh_venv '''ansible all -i inventory -m ping -u root
                       ansible-playbook -i inventory satellite-clone-playbook.yml
                    '''
        }
        else {
                sh_venv '''ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@"${SATELLITE_HOSTNAME}" "satellite-clone -y" '''
        }
    }
}

def perform_upgrade() {
    if (env.PERFORM_UPGRADE == 'true'){
        sh_venv '''
                   fab -u root product_upgrade:"${UPGRADE_PRODUCT}"
                '''
        def directory_existence= sh(script: 'if [ -d upgrade-diff-logs ]; then echo "true"; else echo "false";fi',returnStdout: true).trim()
        if (directory_existence == "true") {
            sh_venv '''tar -czf Log_Analyzer_Logs.tar.xz upgrade-diff-logs'''
        }
    }
}

def existence_test_execution(){
    if (env.RUN_EXISTENCE_TESTS == 'true'){
            ansiColor('xterm') {
                    sh_venv '''
                        set +e
                        export ENDPOINT='cli'
                        $(which py.test) -v --continue-on-collection-errors --junit-xml=test_existance_cli-results.xml -o junit_suite_name=test_existance_cli upgrade_tests/test_existance_relations/cli/
                        export ENDPOINT='api'
                        $(which py.test) -v --continue-on-collection-errors --junit-xml=test_existance_api-results.xml -o junit_suite_name=test_existance_api upgrade_tests/test_existance_relations/api/
                        set -e
                    '''
                }
        }
}

def satellite_backup(){
    if (env.SATELLITE_BACKUP == 'true'){
        sh_venv '''ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@"${SATELLITE_HOSTNAME}" "satellite-maintain backup offline -y /var/backup_directory" '''
    }
}

def mongodb_upgrade() {
    if (env.MONGODB_UPGRADE == 'true'){
        sh_venv ''' fab -H root@"${SATELLITE_HOSTNAME}" mongo_db_engine_upgrade:"SATELLITE" '''
    }
}

def loading_the_groovy_script_to_build_db_environment(){
    script {
            configFileProvider(
                [configFile(fileId: 'bc5f0cbc-616f-46de-bdfe-2e024e84fcbf', variable: 'CONFIG_FILES')]) {
            sh_venv '''
                source ${CONFIG_FILES}
                '''
            conditional_param_execution( param: [env.SATELLITE_HOSTNAME])
            upgrade_environment_variable()
            load('config/sat6_repos_urls.groovy')
            load('config/subscription_config.groovy')
            environment_variable_for_sat6_repos_url()
            environment_variable_for_subscription_config()
        }
    }
}

def workaround(){
    WORKAROUND = env.WORKAROUND ?: binding.hasVariable('WORKAROUND') ? WORKAROUND : ''
    if (WORKAROUND){
       sh_venv ''' ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@"${SATELLITE_HOSTNAME}" "${WORKAROUND}" '''
    }
}

def build_display_name(){
    currentBuild.displayName = "#"+ env.BUILD_NUMBER + "CustDB_Upgrade for_" + env.CUSTOMERDB_NAME  + "_from_" + env.FROM_VERSION + "_to_" + env.TO_VERSION + "_" + env.OS
}

def workspace_cleanup(){
    if (env.WORKSPACE_CLEANUP == 'true'){
        cleanupWs()
    }
}

def upgrade_environment_variable(){
    env.OS_VERSION = sh(script: 'echo ${OS#rhel}',returnStdout: true).trim()
    withCredentials([usernamePassword(credentialsId: 'osp_creds', passwordVariable: 'passWord', usernameVariable: 'userName')]) {
        env.OSP_PASSWORD = passWord
    }
}

def setup_for_existence_test(){
    if (env.UPGRADE_STAGE == "pre") {
        sh_venv '''
            fab -u root setup_products_for_upgrade:"${UPGRADE_PRODUCT}","${OS}"
        '''
    }
    if (env.RUN_EXISTENCE_TESTS == 'true') {
        if (env.UPGRADE_STAGE == "pre"){
            sh_venv '''
                    fab -D -u root set_datastore:"preupgrade","cli"
                    fab -D -u root set_datastore:"preupgrade","api"
                    fab -D -u root set_templatestore:"preupgrade"
                    tar -cf preupgrade_templates.tar.xz preupgrade_templates
                '''
            env.UPGRADE_STAGE = "post"
        }
        else {
            sh_venv '''
                    fab -D -u root set_datastore:"postupgrade","cli"
                    fab -D -u root set_datastore:"postupgrade","api"
                    fab -D -u root set_templatestore:"postupgrade"
                    tar -cf postupgrade_templates.tar.xz postupgrade_templates
                '''
        }
    }
}

def mail_notification(){
    env.BUILD_STATUS = currentBuild.result
    sh_venv '''wget -O mail_report.html https://raw.githubusercontent.com/SatelliteQE/robottelo-ci/master/lib/python/templates/upgrade_report.html
    sed -i "s/Job_Name/${JOB_NAME}/g" mail_report.html
    sed -i "s/CUSTOMERDB_NAME/${CUSTOMERDB_NAME}/g" mail_report.html
    sed -i -- 's#BUILD_URL#'"$BUILD_URL"'#g' mail_report.html
    sed -i "s/STATUS/${BUILD_STATUS}/g" mail_report.html
    sed -i "s/FROM_VERSION/${FROM_VERSION}/g" mail_report.html
    if [ ${FROM_VERSION} == ${TO_VERSION} ]; then TO_VERSION+=".z"; fi
    sed -i "s/TO_VERSION/${TO_VERSION}/g" mail_report.html
    '''

    emailext (
        mimeType: 'text/html',
        subject: "${currentBuild.result}: Job ${env.JOB_NAME} #${env.BUILD_NUMBER}",
        body:'${FILE,path="mail_report.html"}',
        to: "$QE_EMAIL_LIST"
        )
}

def post_upgrade_result(){
    if (env.RUN_EXISTENCE_TESTS == 'true') {
        junit(testResults: '*-results.xml', allowEmptyResults: true)
        archiveArtifacts(artifacts: 'postupgrade_*,preupgrade_*')
    }
}

def environment_variable_for_preupgrade(){
    env.USERNAME = USERNAME
    env.AUTH_URL = AUTH_URL
    env.PROJECT_NAME = PROJECT_NAME
    env.DOMAIN_NAME = DOMAIN_NAME
    env.FLAVOR_NAME = FLAVOR_NAME
    env.NETWORK_NAME = NETWORK_NAME
    env.OSP_SSHKEY =OSP_SSHKEY
    env.RHEL7_IMAGE = RHEL7_IMAGE
    env.RHEL_REPO = RHEL_REPO
    env.DBSERVER = DBSERVER
    env.UPGRADE_STAGE = "pre"
    env.CUST_DB_SERVER = cust_db_server
}

def environment_variable_for_DB(){
    DB_VERSION = sh(script: 'echo ${FROM_VERSION}|sed "s/\\.//g"',returnStdout: true).trim()
    env.CUSTOMERDB_NAME = CUSTOMERDB_NAME + DB_VERSION
    env.DB_URL = DB_URL
}

def environment_variable_for_sat6_upgrade(){
    env.DOCKER_VM = DOCKER_VM
    env.RHEV_CLIENT_AK_RHEL7 = RHEV_CLIENT_AK_RHEL7
    env.RHEV_CLIENT_AK_RHEL6 = RHEV_CLIENT_AK_RHEL6
    env.RHEV_CAPSULE_AK = RHEV_CAPSULE_AK
    env.RHEV_CAP_IMAGE = RHEV_CAP_IMAGE
    env.RHEV_CAP_HOST = RHEV_CAP_HOST
    env.RHEV_SAT_IMAGE = RHEV_SAT_IMAGE
    env.RHEV_SAT_HOST = RHEV_SAT_HOST
    env.RHEL6_CUSTOM_REPO = RHEL6_CUSTOM_REPO
    env.RHEL7_CUSTOM_REPO = RHEL7_CUSTOM_REPO
}

def environment_variable_for_sat6_repos_url(){

    env.TOOLS_RHEL7 = TOOLS_RHEL7
    env.FOREMAN_MAINTAIN_USE_BETA = binding.hasVariable('FOREMAN_MAINTAIN_USE_BETA')?FOREMAN_MAINTAIN_USE_BETA:0
    env.MAINTAIN_REPO = MAINTAIN_REPO
    env.SATELLITE6_REPO = SATELLITE6_REPO
    BASE_URL = env.DISTRIBUTION == "DOWNSTREAM" ? SATELLITE6_REPO: ''
    env.BASE_URL = BASE_URL
}

def environment_variable_for_compute_resource(){
    env.RHEV_USER = RHEV_USER
    env.RHEV_PASSWD = RHEV_PASSWD
    env.RHEV_URL = RHEV_URL
    env.RHEV_CLUSTER = RHEV_CLUSTER
    env.RHEV_STORAGE = RHEV_STORAGE
    env.LIBVIRT_HOSTNAME = LIBVIRT_HOSTNAME
    env.RHEV_DATACENTER = RHEV_DATACENTER
}

def environment_variable_for_subscription_config() {
    env.RHN_USERNAME = RHN_USERNAME
    env.RHN_PASSWORD = RHN_PASSWORD
    env.RHN_POOLID = RHN_POOLID
    env.DOGFOOD_URL = DOGFOOD_URL
    env.DOGFOOD_ORG = DOGFOOD_ORG
    env.distro_path = distro_path
    env.DOGFOOD_ACTIVATIONKEY = DOGFOOD_ACTIVATIONKEY
    env.REPO_FILE_URL = REPO_FILE_URL
}
