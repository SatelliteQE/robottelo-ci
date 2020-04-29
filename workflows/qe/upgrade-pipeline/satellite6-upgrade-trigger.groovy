@Library("github.com/SatelliteQE/robottelo-ci") _

pipeline {
    agent { label "sat6-${satellite_version}" }
    environment {
        CLIENTS_COUNT=8
        SATELLITE_VERSION="${satellite_version}"
        TO_VERSION="${satellite_version}"
        OS="${os}"
        // DISTRO required to load sat6_upgrade.groovy
        DISTRO="${OS}"
    }
    stages {
        stage('Clean Workspace') {
            steps {
                deleteDir()
            }
        }
        stage('Setup environment') {
            steps {
                git branch: branch_selection(SATELLITE_VERSION), url: defaults.satellite6_upgrade
                make_venv python: defaults.python
                check_zstream_upgrade()
                sh_venv '''
                    sed -i "s/nailgun.git.*/nailgun.git@${FROM_VERSION}.z#egg=nailgun/" requirements.txt
                    export PYCURL_SSL_LIBRARY=\$(curl -V | sed -n 's/.*\\(NSS\\|OpenSSL\\).*/\\L\\1/p')
                    pip install -U -r requirements.txt
                    pip install -r requirements-optional.txt
                '''
                }
            }
        stage('Source Variables') {
            steps {

                    loading_the_groovy_script_to_build_environment()
            }
        }
        stage('Setup products for upgrade') {
            steps {
                environment_variable_for_setup_upgrade()
                script {
                sh_venv '''
                fab -u root setup_products_for_upgrade:'longrun',"${OS}"
                '''
                }
            }
        }
        stage("Restart Trigger Pre-upgrade Scenario tests"){
            when {
                isRestartedRun()
            }
            steps{
                loading_the_groovy_script_to_build_environment()
            }
        }
        stage('Trigger Pre-upgrade Scenario tests') {
            steps {
                script {
                   build job: "automation-preupgrade-${satellite_version}-scenario-tests-${os}",
                    parameters: [
                     // get params defined in jenkins config gitlab
                     string(name: 'RHEL6_TOOLS_REPO', value: "${TOOLS_RHEL6}"),
                     string(name: 'RHEL7_TOOLS_REPO', value: "${TOOLS_RHEL7}"),
                     string(name: 'CAPSULE_REPO', value: "${CAPSULE_REPO}"),
                     string(name: 'SUBNET', value: "${SUBNET}"),
                     string(name: 'NETMASK', value: "${NETMASK}"),
                     string(name: 'GATEWAY', value: "${GATEWAY}"),
                     string(name: 'BRIDGE', value: "${BRIDGE}"),
                     string(name: 'DISCOVERY_ISO', value: "${DISCOVERY_ISO}"),
                     string(name: 'SERVER_HOSTNAME', value: "${RHEV_SAT_HOST}"),
                     // get params defined in trigger
                     booleanParam(name: 'PERFORM_FOREMAN_MAINTAIN_UPGRADE', value: "${params.PERFORM_FOREMAN_MAINTAIN_UPGRADE}"),
                     booleanParam(name: 'ZSTREAM_UPGRADE', value: "${params.ZSTREAM_UPGRADE}"),
                     booleanParam(name: 'DESTRUCTIVE_TEST_CASE_EXECUTION', value: "${params.DESTRUCTIVE_TEST_CASE_EXECUTION}"),
                     string(name: 'ROBOTTELO_WORKERS', value: "${params.ROBOTTELO_WORKERS}"),
                     string(name: 'BUILD_LABEL', value: "${params.BUILD_LABEL}"),
                    ], wait: false
                }
            }
        }
    }
    post {
    failure {
        send_automation_email "failure"
    }
    fixed {
        send_automation_email "fixed"
    }
    always {
        archiveArtifacts(artifacts: 'product_setup')
    }
    }
}


def check_zstream_upgrade() {
    if ("${params.ZSTREAM_UPGRADE}" == 'true') {
        env.FROM_VERSION = TO_VERSION
    }
    else {
        env.FROM_VERSION = sh(script: 'echo `echo "${SATELLITE_VERSION} - 0.1"|bc`',returnStdout: true).trim()
    }
}

def loading_the_groovy_script_to_build_environment(){
     configFileProvider([configFile(fileId: 'bc5f0cbc-616f-46de-bdfe-2e024e84fcbf', variable: 'CONFIG_FILES')]) {
        sh_venv '''source ${CONFIG_FILES}'''
        load('config/compute_resources.groovy')
        load('config/installation_environment.groovy')
        load('config/sat6_upgrade.groovy')
        load('config/sat6_repos_urls.groovy')
        load('config/subscription_config.groovy')
        script {
                currentBuild.displayName = "# ${env.BUILD_NUMBER} Upgrade_${os}_to_${satellite_version} ${env.BUILD_LABEL}"
        }
    }
}

def environment_variable_for_setup_upgrade() {
    env.HTTP_SERVER_HOSTNAME = HTTP_SERVER_HOSTNAME
    // required for get_rhevm4_client() from satellite6-upgrade
    env.RHEV_USER = RHEV_USER
    env.RHEV_PASSWD = RHEV_PASSWD
    env.RHEV_URL = RHEV_URL
    // required for satellite6_setup and satellite6_capsule_setup from satellite6-upgrade
    env.RHEV_SAT_IMAGE = RHEV_SAT_IMAGE
    env.RHEV_SAT_HOST = RHEV_SAT_HOST
    env.RHEV_CAP_HOST = RHEV_CAP_HOST
    env.RHEV_CAP_IMAGE = RHEV_CAP_IMAGE
    env.RHEV_CAPSULE_AK = RHEV_CAPSULE_AK
    env.RHEL6_CUSTOM_REPO = RHEL6_CUSTOM_REPO
    env.RHEL7_CUSTOM_REPO = RHEL7_CUSTOM_REPO
    // required for satellite6_client_setup from satellite6-upgrade
    env.DOCKER_VM = DOCKER_VM
    env.RHEV_CLIENT_AK_RHEL6 = RHEV_CLIENT_AK_RHEL6
    env.RHEV_CLIENT_AK_RHEL7 = RHEV_CLIENT_AK_RHEL7
    env.RHEV_DATACENTER_UUID = RHEV_DATACENTER_UUID
    env.RHEV_STORAGE = RHEV_STORAGE
    env.RHEV_CLUSTER = RHEV_CLUSTER
    env.RHEV_DATACENTER = RHEV_DATACENTER
    env.TOOLS_URL_RHEL6 = TOOLS_RHEL6
    env.TOOLS_URL_RHEL7 = TOOLS_RHEL7
    env.TOOLS_URL_RHEL8 = binding.hasVariable('TOOLS_RHEL8')?TOOLS_RHEL8:"None"
    // required for subscribe task from automation_tools
    env.RHN_PASSWORD = RHN_PASSWORD
    env.RHN_USERNAME = env.RHN_USERNAME
    env.RHN_POOLID = env.RHN_POOLID
    // required for _sync_capsule_subscription_to_capsule_ak from satellite6-upgrade
    env.CAPSULE_URL = CAPSULE_REPO
}
