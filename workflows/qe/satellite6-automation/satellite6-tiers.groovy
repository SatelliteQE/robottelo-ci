@Library("github.com/SatelliteQE/robottelo-ci") _

pipeline {

 agent {
  label "docker"
   }

options {
  // Build discarder
  buildDiscarder(logRotator(numToKeepStr: '32'))
  // Implement resource locking for tier jobs
  lock(label: "${ENDPOINT}_block")
  // Disable Concurrent builds
  disableConcurrentBuilds()
  // Load sauce settings
  sauce('e20b4b28-acfd-44e2-811d-5c43902593a7')
  sauceconnect(options: '', sauceConnectPath: '', useGeneratedTunnelIdentifier: true, verboseLogging: true)
 }

 stages {
  stage('Set build name and Virtualenv') {
   steps {
    cleanWs()
    make_venv python: defaults.python, venvModule: 'venv'
   }
  }
  stage('Source Config and Variables') {
   steps {
    configFileProvider(
     [configFile(fileId: 'bc5f0cbc-616f-46de-bdfe-2e024e84fcbf', variable: 'CONFIG_FILES')]) {
     sh_venv 'source ${CONFIG_FILES}'
     load('config/provisioning_environment.groovy')
     load('config/provisioning_env_with_endpoints.groovy')
     script {
      // Provisioning jobs TARGET_IMAGE becomes the SOURCE_IMAGE for Tier and RHAI jobs.
      // source-image at this stage for example: qe-sat63-rhel7-base
      SOURCE_IMAGE = TIER_SOURCE_IMAGE
      // target-image at this stage for example: qe-sat63-rhel7-tier1
      TARGET_IMAGE = TIER_SOURCE_IMAGE.replace('base', ENDPOINT)
      SERVER_HOSTNAME = "${TARGET_IMAGE}.${VM_DOMAIN}"
     }
    }
   }
  }
  stage("Remove older Satellite Instance from Provisioning Host") {
   steps {
    withCredentials([sshUserPrivateKey(credentialsId: 'id_hudson_rsa', keyFileVariable: 'identity', usernameVariable: 'userName')]) {
     script {
      remote = [name: "Provisioning server ${PROVISIONING_HOST}", allowAnyHosts: true, host: PROVISIONING_HOST, user: userName, identityFile: identity]
      sshCommand remote: remote, command: "virsh destroy ${TARGET_IMAGE} || true"
      sshCommand remote: remote, command: "virsh undefine ${TARGET_IMAGE} || true"
      sshCommand remote: remote, command: "virsh vol-delete --pool default /var/lib/libvirt/images/${TARGET_IMAGE}.img || true"
     }
    }
   }
  }
  stage('Setup Satellite Tier Instance') {

   steps {
    withCredentials([sshUserPrivateKey(credentialsId: 'id_hudson_rsa', keyFileVariable: 'identity', usernameVariable: 'userName')]) {

     script {
     // Create the Satellite Instance
      remote = [name: "Provisioning server ${PROVISIONING_HOST}", allowAnyHosts: true, host: PROVISIONING_HOST, user: userName, identityFile: identity]
      sshCommand remote: remote, command: "snap-guest -b ${SOURCE_IMAGE} -t ${TARGET_IMAGE} --hostname ${SERVER_HOSTNAME} \
    -m ${VM_RAM} -c ${VM_CPU} -d ${VM_DOMAIN} -f -n bridge=${BRIDGE} --static-ipaddr ${TIER_IPADDR} \
    --static-netmask ${NETMASK} --static-gateway ${GATEWAY}"
     }
     script {
     // Check if the satellite instance is ready
      remote = [name: "Satellite server ${TIER_IPADDR}", allowAnyHosts: true, host: TIER_IPADDR, user: userName, identityFile: identity]
      timeout(time: 4, unit: 'MINUTES') {
       retry(120) {
        sleep(2)
        echo "Checking if box with ${TIER_IPADDR} is up yet.."
        sshCommand remote: remote, command: 'date'
       }
       echo "Box is successfully up or we have hit 4 mins timeout"
      }
     }
     script {
      remote = [: ]
      //Restart Satellite6 service for a clean state of the running instance.
      def tier_name = TIER_SOURCE_IMAGE.replace('-base', '.') + VM_DOMAIN
      def tier_short_name = TIER_SOURCE_IMAGE.replace('-base', '')
      remote = [name: "Satellite server", allowAnyHosts: true, host: SERVER_HOSTNAME, user: userName, identityFile: identity]
      sshCommand remote: remote, command: "hostnamectl set-hostname ${tier_name}"
      sshCommand remote: remote, command: "sed -i '/redhat.com/d' /etc/hosts"
      sshCommand remote: remote, command: "echo ${TIER_IPADDR} ${tier_name} ${tier_short_name} >> /etc/hosts"
      sshCommand remote: remote, command: "katello-service restart"
      timeout(time: 4, unit: 'MINUTES') {
       retry(240) {
        sleep(10)
        echo "Checking if hammer ping works "
        sshCommand remote: remote, command: 'hammer ping'
       }
       echo "hammer ping is successfully up or we have hit 4 mins timeout"
      }
      // changing Satellite6 hostname (supported on Sat6.2+)
      rename_cmd = (SATELLITE_VERSION == "upstream-nightly") ? "katello-change-hostname" : "satellite-change-hostname"
      rename_cmd = "${rename_cmd} ${SERVER_HOSTNAME} -y -u admin -p changeme"
      sshCommand remote: remote, command: rename_cmd

      if (ENDPOINT != 'tier3' && 'tier4') {
       sshCommand remote: remote, command: "systemctl stop dhcpd"
      }
     }
    }
   }
  }
 stage("Configure robottelo according to tier instance") {
   steps {
    script {
     // Clone the robottelo repo into workspace
     checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'robottelodir']], submoduleCfg: [], userRemoteConfigs: [[url: 'https://github.com/SatelliteQE/robottelo']]])
     configFileProvider(
      [configFile(fileId: 'bc5f0cbc-616f-46de-bdfe-2e024e84fcbf', variable: 'CONFIG_FILES')]) {
      // Start to populate robottelo.properties file
      sh_venv '''
      source ${CONFIG_FILES}
      cp config/robottelo.properties robottelo.properties
      cp config/robottelo.yaml robottelo.yaml
      cp -r robottelodir/* .
      # Robottelo logging configuration
      sed -i "s/'robottelo.log'/'robottelo-${ENDPOINT}.log'/" logging.conf
      '''
      // Sauce Labs Configuration and pytest-env setting.
      if ("${SATELLITE_VERSION}" != "6.3" ){
        SAUCE_BROWSER="chrome"
        sh_venv '''
        pip install -U pytest-env

        env =
            PYTHONHASHSEED=0
        '''
      }
      withCredentials([string(credentialsId: 'SAUCELABS_KEY', variable: 'SAUCELABS_KEY'), string(credentialsId: 'BZ_API_KEY', variable: 'BZ_API_KEY')]) {
      sauce_args = [:]
      image_args = [:]
      network_args = [:]
      dist_args = [:]
      BROWSER_VERSION = ''
      SELENIUM_VERSION = ''
      if ( "${SAUCE_PLATFORM}" != "no_saucelabs" ) {
        echo "The Sauce Tunnel Identifier for Server Hostname ${SERVER_HOSTNAME} is ${TUNNEL_IDENTIFIER}"
        if ( "${SAUCE_BROWSER}" == "edge" ){
            BROWSER_VERSION='14.14393'
            }
        else if ( "${SAUCE_BROWSER}" == "chrome" ) {
            BROWSER_VERSION='63.0'
        }
        if ( "${SATELLITE_VERSION}" == "6.4" ) {
            SELENIUM_VERSION='3.14.0'
            }
        else {
            SELENIUM_VERSION='3.141.0'
             }
        sauce_args = ['browser': 'saucelabs',
                 'saucelabs_user': env.SAUCELABS_USER,
                 'saucelabs_key': SAUCELABS_KEY,
                 'webdriver':  "${SAUCE_BROWSER}",
                 'webdriver_desired_capabilities' : "platform=${SAUCE_PLATFORM},version=${BROWSER_VERSION},maxDuration=5400,idleTimeout=1000,seleniumVersion=${SELENIUM_VERSION},build=${env.BUILD_LABEL},screenResolution=1600x1200,tunnelIdentifier=${TUNNEL_IDENTIFIER},extendedDebugging=true,tags=[${env.JOB_NAME}]"
                  ]
      }
      else {
      //use zalenium
        sauce_args = [
                 'webdriver': 'chrome',
                 'webdriver_desired_capabilities' : "platform=ANY,maxDuration=5400,idleTimeout=1000,start-maximised=true,screenResolution=1600x1200,tags=[${env.JOB_NAME}]"
                  ]
      }

      // If Image Parameter is checked
      if (IMAGE != null){
        image_agrs = ['[distro]': '',
                    'image_el6': IMAGE,
                    'image_el7': IMAGE,
                    'image_el8': IMAGE,
                    ]

        }
       // upstream = 1 for Distributions: UPSTREAM (default in robottelo.properties)
       // upstream = 0 for Distributions: DOWNSTREAM, CDN, BETA, ISO
      if ( !SATELLITE_VERSION.contains('upstream-nightly')) {
       // To set the discovery ISO name in properties file
       network_args = ['upstream':'false',
                    '[vlan_networking]':'',
                    'subnet':SUBNET,
                    'netmask': NETMASK,
                    'gateway': GATEWAY,
                    'bridge': BRIDGE,
                    '[discovery]':'',
                    'discovery_iso': DISCOVERY_ISO
                    ]
      }
      // cdn = 1 for Distributions: GA (default in robottelo.properties)
      // cdn = 0 for Distributions: INTERNAL, BETA, ISO
      // Sync content and use the below repos only when DISTRIBUTION is not GA
       if ( !SATELLITE_DISTRIBUTION.contains('GA')) {
        //The below cdn flag is required by automation to flip between RH & custom syncs.
        dist_args = ['cdn': 'false',
                    'sattools_repo': "rhel8=${RHEL8_TOOLS_REPO},rhel7=${RHEL7_TOOLS_REPO},rhel6=${RHEL6_TOOLS_REPO}",
                    'capsule_repo': CAPSULE_REPO
                    ]
        }
        // Bugzilla Login Details
        //AWS Access Keys Configuration
        //Robottelo Capsule Configuration
        all_args = [
                                                                'hostname': SERVER_HOSTNAME,
                                                                'screenshots_path': "${WORKSPACE}//screenshots",
                                                                'external_url': "http://${SERVER_HOSTNAME}:2375",
                                                                'bz_api_key': BZ_API_KEY,
                                                                'bz_url': 'https://bugzilla.redhat.com',
                                                                'access_key': env.AWS_ACCESSKEY_ID,
                                                                'secret_key': env.AWS_ACCESSKEY_SECRET,
                                                                '[capsule]':'',
                                                                'instance_name': SERVER_HOSTNAME.split('\\.')[0] + '-capsule',
                                                                'domain': DDNS_DOMAIN,
                                                                'hash': CAPSULE_DDNS_HASH,
                                                                'ddns_package_url': DDNS_PACKAGE_URL
                                                                ] + sauce_args + image_agrs + network_args + dist_args
      parse_ini ini_file: "${WORKSPACE}//robottelo.properties" , properties: all_args
    }
    }
    }
   }
  }
  stage("Configure dependencies and pytest"){
   steps {
    script {
    sh_venv '''
    set +e
    pip install -U -r requirements.txt docker-py pytest-xdist==1.25.0 sauceclient
    set -e
    '''
     EXTRA_MARKS = SATELLITE_VERSION.contains("*upstream-nightly*") ? '' : "and upgrade"
    }
    withCredentials([sshUserPrivateKey(credentialsId: 'id_hudson_rsa', keyFileVariable: 'identity', usernameVariable: 'userName')]) {
      script {
        remote = [name: "Satellite server", allowAnyHosts: true, host: SERVER_HOSTNAME, user: userName, identityFile: identity]
        sshCommand remote: remote, command: 'cp /root/.hammer/cli.modules.d/foreman.yml{,_orig}'
      }
    }
  }
  }
  stage("Run Destructive tests"){
  when{
        expression { "${ENDPOINT}".contains("destructive") }
  }
  steps {
    script{
      sh_venv '''
      set +e
      make test-foreman-sys
      set -e
      '''
  }
  }
  }
  stage("Run Sequential Tests"){
  when {
        expression{ !"${ENDPOINT}".contains("rhai") }
  }
  steps{
    script{
        sh_venv '''
         TEST_TYPE="$(echo tests/foreman/{api,cli,ui,longrun,sys,installer})"
         set +e
         # Run sequential tests
        $(which py.test) -v --junit-xml="${ENDPOINT}-sequential-results.xml" \
            -o junit_suite_name="${ENDPOINT}-sequential" \
            -m "${ENDPOINT} and run_in_one_thread and not stubbed ${EXTRA_MARKS}" \
            ${TEST_TYPE}
        set -e
        '''

  }
  }
  }
    stage("Run Parallel Tests"){
  when {
        expression{ !"${ENDPOINT}".contains("rhai") }
  }
  steps{
    script{
        sh_venv '''
         TEST_TYPE="$(echo tests/foreman/{api,cli,ui,longrun,sys,installer})"
         set +e
        # Run parallel tests
        $(which py.test) -v --junit-xml="${ENDPOINT}-parallel-results.xml" -n "${ROBOTTELO_WORKERS}" \
        -o junit_suite_name="${ENDPOINT}-parallel" \
        -m "${ENDPOINT} and not run_in_one_thread and not stubbed ${EXTRA_MARKS}" \
        ${TEST_TYPE}
        set -e
        '''
  }
  }
  }
  stage("Run Rhai and clean ups"){
    when {
        expression{"${ENDPOINT}".contains("rhai")}
  }
  steps{
  script{
      sh_venv '''
      set +e
      make test-foreman-rhai PYTEST_XDIST_NUMPROCESSES=${ROBOTTELO_WORKERS}
      set -e
      '''
  }
  }
  }
  stage("Trigger Polarion Build"){
    steps{
     //Trigger Polarion Builds
      build job: "polarion-test-run-${satellite_version}-${DISTRO}",
       parameters: [
        string(name: 'TEST_RUN_ID', value: "${params.BUILD_LABEL} ${DISTRO}"),
        string(name: 'POLARION_RELEASE', value: "${params.BUILD_LABEL}"),
        string(name: 'ENDPOINT', value: "${ENDPOINT}"),
        booleanParam(name: 'PULL_ARTIFACTS', value: true)
       ],
       propagate: false,
       wait: false
  }
  }
  }

post {
    failure {
        withCredentials([sshUserPrivateKey(credentialsId: 'id_hudson_rsa', keyFileVariable: 'identity', usernameVariable: 'userName')]) {
        script{
         remote = [name: "Satellite server", allowAnyHosts: true, host: PROVISIONING_HOST, user: userName, identityFile: identity]
         // Graceful shutdown for tier box
         echo "Destroy the Tier Instance as the job has failed. Destroying ${SERVER_HOSTNAME} gracefully"
         sshCommand remote: remote, command: "virsh destroy ${TARGET_IMAGE} || true"
        }
        }
            send_automation_email "failure"
        }
    fixed {
            send_automation_email "fixed"
    }
    always {
       archiveArtifacts(artifacts: '*.log,*-results.xml,*.xml', allowEmptyArchive: true)
       withCredentials([sshUserPrivateKey(credentialsId: 'id_hudson_rsa', keyFileVariable: 'identity', usernameVariable: 'userName')]) {
        script {
        // Joins the workers separate logs file into one single log
            if ("${ROBOTTELO_WORKERS}" > 0) {
                sh_venv '''
                    set +e
                    make logs-join
                    make logs-clean
                    set -e
                '''
            }
            junit allowEmptyResults: true,
            healthScaleFactor: 0.0,
            testDataPublishers: [[$class: 'ClaimTestDataPublisher'],
            [$class: 'StabilityTestDataPublisher']],
            testResults: '*-results.xml'
             remote = [name: "Satellite server", allowAnyHosts: true, host: SERVER_HOSTNAME, user: userName, identityFile: identity]
             sshCommand remote: remote, command: 'cp /root/.hammer/cli.modules.d/foreman.yml{_orig,}'
             sshCommand remote: remote, command: 'foreman-debug -s 0 -q -d "/tmp/foreman-debug"'
             sshGet remote: remote, from: '/tmp/foreman-debug.tar.xz', into: '.', override: true
             // Start Code coverage
             if (SATELLITE_DISTRIBUTION != 'UPSTREAM' || 'KOJI') {
                get_code_coverage(ENDPOINT, 'python')
             }
             if ("${RUBY_CODE_COVERAGE}" == "true") {
                get_code_coverage(ENDPOINT, 'ruby')
             }
            cobertura autoUpdateHealth: false,
            autoUpdateStability: false,
            coberturaReportFile: 'coverage.xml',
            failNoReports: false,
            failUnhealthy: false,
            failUnstable: false,
            fileCoverageTargets: '10, 30, 20',
            maxNumberOfBuilds: 0,
            methodCoverageTargets: '50, 30, 40',
            onlyStable: false,
            sourceEncoding: 'ASCII',
            zoomCoverageChart: false

         }
         }
        withCredentials([sshUserPrivateKey(credentialsId: 'id_hudson_rsa', keyFileVariable: 'identity',usernameVariable: 'userName')]) {
        script{
         remote = [name: "Provisioning serverr", allowAnyHosts: true, host: PROVISIONING_HOST, user: userName, identityFile: identity]
         sshCommand remote: remote, command: "virsh shutdown ${TARGET_IMAGE} || true"
         sshCommand remote: remote, command: 'sleep 120'

         echo "========================================"
         echo "Server information"
         echo "========================================"
         echo "Hostname: ${SERVER_HOSTNAME}"
         echo "Credentials: admin/changeme"
         echo "========================================"
         echo "========================================"

         }
         }
  }
 }
}


def get_code_coverage(String ENDPOINT, String coverage) {
   withCredentials([sshUserPrivateKey(credentialsId: 'id_hudson_rsa', keyFileVariable: 'identity', usernameVariable: 'userName')]) {
   script {
    remote = [name: "Satellite server", allowAnyHosts: true, host: SERVER_HOSTNAME, user: userName, identityFile: identity]
    if (coverage == 'python') {
        // Shutdown the Satellite6 services for collecting coverage.
        sshCommand remote: remote, command: 'katello-service stop || true'
        // Create tar file for each of the Tier .coverage files to create a consolidated coverage report.
        sshCommand remote: remote, command: "cd /etc/coverage ; tar -cvf coverage.${ENDPOINT}.tar .coverage.*"
        // Combine the coverage output to a single file and create a xml file.
        sshCommand remote: remote, command: 'cd /etc/coverage/ ; coverage combine'
        sshCommand remote: remote, command: 'cd /etc/coverage/ ; coverage xml'
        // Fetch the coverage.xml file to the project folder.
        sshGet remote: remote, from: '/etc/coverage/coverage.xml', into: '.', override: true
        // Fetch the coverage.${ENDPOINT}.tar file to the project folder.
        sshGet remote: remote, from: "/etc/coverage/coverage.${ENDPOINT}.tar", into: '.', override: true
    }
    else{
        // Create tar file for each of the Tier Coverage Report files to create a consolidated coverage report.
        sshCommand remote: remote, command: "cd /etc/coverage/ruby/tfm/reports/ ; tar -cvf /root/tfm_reports_${ENDPOINT}.tar ./."
        // Fetch the tfm_reports.${ENDPOINT}.tar file to the project folder.
        sshGet remote: remote, from: "/root/tfm_reports_${ENDPOINT}.tar", into: '.', override: true
    }
   }
  }
 }
