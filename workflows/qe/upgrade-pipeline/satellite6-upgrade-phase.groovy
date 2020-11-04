@Library("github.com/SatelliteQE/robottelo-ci") _

pipeline {
    agent { label "sat6-${satellite_version}" }
    environment {
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
                sh_venv '''
                    export PYCURL_SSL_LIBRARY=\$(curl -V | sed -n 's/.*\\(NSS\\|OpenSSL\\).*/\\L\\1/p')
                    pip install -U -r requirements.txt
                    pip install -r requirements-optional.txt
                '''
                }
            }
        stage('Source Variables') {
            steps {
                    check_zstream_upgrade()
                    loading_the_groovy_script_to_build_upgrade_phase_environment()
            }
        }
        stage('Setting up pre-upgrade data-store for existence tests') {
            steps {
                copyArtifacts(filter:'scenario_entities,product_setup',
                    projectName: "automation-preupgrade-${satellite_version}-scenario-tests-${os}",
                    selector: lastSuccessful())
                sh_venv '''
                    fab -u root set_datastore:"preupgrade","cli"
                    fab -u root set_datastore:"preupgrade","api"
                    fab -u root set_templatestore:"preupgrade"
                    tar -cf preupgrade_templates.tar.xz preupgrade_templates
                '''
            }
        }
        stage('Upgrade Satellite, Capsule and Clients') {
            steps {
                ansiColor('xterm') {
                    sh_venv '''
                        fab -u root product_upgrade:'longrun'
                    '''
                }
            }
        }
        stage('Setting up post-upgrade data-store for existence tests') {
            steps {
                sh_venv '''
                    fab -u root set_datastore:"postupgrade","cli"
                    fab -u root set_datastore:"postupgrade","api"
                    fab -u root set_templatestore:"postupgrade"
                    tar -cf postupgrade_templates.tar.xz postupgrade_templates
                '''
            }
        }
        stage('Delete old scap_content') {
            steps {
                script {
                    sh_venv '''
                        set +e
                        fab -u root update_scap_content
                        set -e
                    '''
                }
            }
        }
        stage("Restart Trigger Existence Tests Job"){
            when {
                isRestartedRun()
            }
            steps{
                loading_the_groovy_script_to_build_upgrade_phase_environment()
            }
        }
        stage('Trigger Existence Tests Job') {
            steps {
                script {
                   build job: "automation-upgraded-${satellite_version}-existence-tests-${os}",
                    parameters: [
                     // get params defined in jenkins config gitlab
                     string(name: 'RHEL6_TOOLS_REPO', value: "${TOOLS_RHEL6}"),
                     string(name: 'RHEL7_TOOLS_REPO', value: "${TOOLS_RHEL7}"),
                     string(name: 'RHEL8_TOOLS_REPO', value: "${TOOLS_RHEL8}"),
                     string(name: 'CAPSULE_REPO', value: "${CAPSULE_REPO}"),
                     string(name: 'SUBNET', value: "${SUBNET}"),
                     string(name: 'NETMASK', value: "${NETMASK}"),
                     string(name: 'GATEWAY', value: "${GATEWAY}"),
                     string(name: 'BRIDGE', value: "${BRIDGE}"),
                     string(name: 'DISCOVERY_ISO', value: "${DISCOVERY_ISO}"),
                     string(name: 'SERVER_HOSTNAME', value: "${RHEV_SAT_HOST}"),
                     // get params defined in trigger
                     booleanParam(name: 'FOREMAN_MAINTAIN_SATELLITE_UPGRADE', value: "${params.FOREMAN_MAINTAIN_SATELLITE_UPGRADE}"),
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
    success {
        emailext (
          to: "${env.QE_EMAIL_LIST}",
          subject: "Upgrade Status to ${satellite_version} on ${os} ${BUILD_LABEL} - ${currentBuild.currentResult}",
          body: '${FILE, path="upgrade_highlights"}' + "The build ${env.BUILD_URL} has been completed.",
          attachmentsPattern: 'full_upgrade, Log_Analyzer_Logs.tar.xz'
        )
    }
    failure {
        send_automation_email "failure"
    }
    always {
        archiveArtifacts(artifacts: '*.tar.xz,preupgrade_*,postupgrade_*,scenario_entities,product_setup')
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

def loading_the_groovy_script_to_build_upgrade_phase_environment(){
    configFileProvider([configFile(fileId: 'bc5f0cbc-616f-46de-bdfe-2e024e84fcbf', variable: 'CONFIG_FILES')]) {
    sh_venv '''
        source ${CONFIG_FILES}
    '''
    load('config/compute_resources.groovy')
    load('config/installation_environment.groovy')
    load('config/sat6_upgrade.groovy')
    load('config/sat6_repos_urls.groovy')
    load('config/subscription_config.groovy')
    load('config/fake_manifest.groovy')
    }
    environment_variable_for_upgrade()
    script {
        currentBuild.displayName = "# ${env.BUILD_NUMBER} Upgrade_${os}_to_${satellite_version} ${env.BUILD_LABEL}"
    }
}

def environment_variable_for_upgrade() {
    env.HTTP_SERVER_HOSTNAME = HTTP_SERVER_HOSTNAME
    // required for product_upgrade task from satellite6-upgrade
    env.RHEV_USER = RHEV_USER
    env.RHEV_PASSWD = RHEV_PASSWD
    env.RHEV_URL = RHEV_URL
    env.RHEV_SAT_IMAGE = RHEV_SAT_IMAGE
    env.RHEV_SAT_HOST = RHEV_SAT_HOST
    env.RHEV_CAP_HOST = RHEV_CAP_HOST
    env.RHEV_CAP_IMAGE = RHEV_CAP_IMAGE
    env.RHEV_CAPSULE_AK = RHEV_CAPSULE_AK
    env.RHEL6_CUSTOM_REPO = RHEL6_CUSTOM_REPO
    env.RHEL7_CUSTOM_REPO = RHEL7_CUSTOM_REPO
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
    // required for satellite6_upgrade
    env.BASE_URL = SATELLITE6_REPO
    env.CAPSULE_URL = CAPSULE_REPO
    // required for setup_foreman_maintain
    env.TOOLS_RHEL7 = TOOLS_RHEL7
    env.MAINTAIN_REPO = MAINTAIN_REPO
    // required for post_upgrade_test_tasks from satellite6_upgrade
    env.FAKE_MANIFEST_CERT_URL = FAKE_MANIFEST_CERT_URL
    env.LIBVIRT_HOSTNAME = LIBVIRT_HOSTNAME
    // required for get_discovery_image task from automation-tools
    env.DISCOVERY_ISO = DISCOVERY_ISO
    env.GATEWAY = GATEWAY
    env.IPADDR = IPADDR
}
