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
                git branch: branch_selection(SATELLITE_VERSION), url: defaults.robottelo
                make_venv python: defaults.python
                check_zstream_upgrade()
                // https://github.com/SatelliteQE/robottelo-ci/issues/1873
                sh_venv '''
                    # Installing nailgun according to FROM_VERSION
                    sed -i "s/nailgun.git.*/nailgun.git@${FROM_VERSION}.z#egg=nailgun/" requirements.txt
                    export PYCURL_SSL_LIBRARY=\$(curl -V | sed -n 's/.*\\(NSS\\|OpenSSL\\).*/\\L\\1/p')
                    pip install -U "pip<21.0"
                    pip install -U --use-deprecated=legacy-resolver -r requirements.txt sauceclient
                    pip install -r requirements-optional.txt
                '''
                }
            }
        stage('Source Variables') {
            steps {
                loading_the_groovy_script_to_build_post_upgrade_environment()
            }
        }
        stage('Build for running test') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'id_hudson_rsa', keyFileVariable: 'identity', usernameVariable: 'userName')]) {
                script {
                 remote = [name: "Satellite server", allowAnyHosts: true, host: "${SERVER_HOSTNAME}", user: userName, identityFile: identity]
                 echo "Setting up fake manifest certificate"
                 sshCommand remote: remote, command: "wget -O /etc/candlepin/certs/upstream/fake_manifest.crt ${FAKE_MANIFEST_CERT_URL};systemctl restart tomcat"
                }
                }
                copyArtifacts(filter:'product_setup,scenario_entities',
                    projectName: "automation-upgraded-${satellite_version}-existence-tests-${os}",
                    selector: lastSuccessful())
            }
        }
        stage('Run Post-upgrade Scenario Tests') {
            steps {
                environment_variable_for_postupgrade_tests()
                environment_variable_for_postupgrade_test_decorator()
                browser_update()
                sh_venv '''
                    set +e
                    $(which py.test) -v --continue-on-collection-errors -s -m "${post_upgrade_decorator}" --junit-xml=test_scenarios-post-results.xml -o junit_suite_name=test_scenarios-post tests/upgrades
                    set -e
                '''
                withCredentials([sshUserPrivateKey(credentialsId: 'id_hudson_rsa', keyFileVariable: 'identity', usernameVariable: 'userName')]) {
                script {
                 remote = [name: "Satellite server", allowAnyHosts: true, host: "${SERVER_HOSTNAME}", user: userName, identityFile: identity]
                 echo "Delete the Original Manifest from the box to run robottelo tests"
                 sshCommand remote: remote, command: "hammer -u admin -p changeme subscription delete-manifest --organization 'Default Organization'"
                }
                }
            }
        }
        stage('Trigger satellite 6 manifest downloader job') {
            steps {
                script {
                    build job: "satellite6-manifest-downloader"
                }
            }
        }
        stage("Restart Trigger Robottelo Tests with upgrade decorator"){
            when {
                isRestartedRun()
            }
            steps{
                loading_the_groovy_script_to_build_post_upgrade_environment()
            }
        }
        stage('Trigger Robottelo Tests with upgrade decorator') {
            steps {
                script {
                   build job: "automation-upgraded-${satellite_version}-all-tiers-${os}",
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
        junit(testResults: '*-results.xml', allowEmptyResults: true)
        archiveArtifacts(artifacts: 'scenario_entities,product_setup')
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

def loading_the_groovy_script_to_build_post_upgrade_environment(){
    configFileProvider([configFile(fileId: 'bc5f0cbc-616f-46de-bdfe-2e024e84fcbf', variable: 'CONFIG_FILES')]) {
    sh_venv '''
        source ${CONFIG_FILES}
        cp config/robottelo.properties ./robottelo.properties
        cp config/robottelo.yaml ./robottelo.yaml
        cp config/virtwho.properties ./virtwho.properties
        cp config/broker_settings.yaml ./broker_settings.yaml
        sed -i "s/'robottelo.log'/'robottelo-${ENDPOINT}.log'/" logging.conf
    '''
    load('config/compute_resources.groovy')
    load('config/sat6_upgrade.groovy')
    load('config/sat6_repos_urls.groovy')
    load('config/subscription_config.groovy')
    load('config/fake_manifest.groovy')
    }
    script {
        currentBuild.displayName = "# ${env.BUILD_NUMBER} postupgrade-scenarios-Upgrade_${os}_to_${satellite_version} ${env.BUILD_LABEL}"
        network_args = ['[vlan_networking]':'',
        'subnet': "${SUBNET}",
        'netmask': "${NETMASK}",
        'gateway': "${GATEWAY}",
        'bridge': "${BRIDGE}"
        ]
        upgrade_args = ['rhev_cap_host':"${RHEV_CAP_HOST}",
        'rhev_capsule_ak':"${RHEV_CAPSULE_AK}",
        'from_version':"${FROM_VERSION}",
        'to_version': "${TO_VERSION}"
        ]
        withCredentials([string(credentialsId: 'BZ_API_KEY', variable: 'BZ_API_KEY'), string(credentialsId: 'BUGZILLA_PASSWORD', variable: 'BUGZILLA_PASSWORD'), string(credentialsId: 'SAUCELABS_KEY', variable: 'SAUCELABS_KEY')]) {
        all_args = [
        'hostname': "${RHEV_SAT_HOST}",
        'api_key': "${BZ_API_KEY}",
        'saucelabs_user': "${SAUCELABS_USER}",
        'saucelabs_key': "${SAUCELABS_KEY}",
        'bz_password': "${BUGZILLA_PASSWORD}",
        'sattools_repo': "rhel8=${TOOLS_RHEL8},rhel7=${TOOLS_RHEL7},rhel6=${TOOLS_RHEL6}",
        'capsule_repo': "${CAPSULE_REPO}"] + network_args + upgrade_args
        }
        parse_ini ini_file: "${WORKSPACE}//robottelo.properties" , properties: all_args
    }
}

def environment_variable_for_postupgrade_test_decorator(){
    if ("${params.DESTRUCTIVE_TEST_CASE_EXECUTION}" == 'true'){
        env.post_upgrade_decorator = "post_upgrade"
    }
    else {
        env.post_upgrade_decorator = "not destructive and post_upgrade"
    }
}

def browser_update(){
    if (env.BROWSER == "saucelabs") {
        sh_venv ''' sed -i "s/browser=remote/browser=saucelabs/g" robottelo.properties'''
    }
}

def environment_variable_for_postupgrade_tests() {
    // required for dockerize upgrade_tests helper
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
    env.BROWSER = 'remote'
    env.RHEV_USER = RHEV_USER
    env.RHEV_PASSWD = RHEV_PASSWD
    env.RHEV_URL = RHEV_URL
    env.RHEV_SAT_HOST = RHEV_SAT_HOST
}
