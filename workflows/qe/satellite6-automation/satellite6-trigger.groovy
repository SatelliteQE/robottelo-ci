@Library("github.com/SatelliteQE/robottelo-ci") _

pipeline {

 agent {
  label "sat6-rhel"
 }

 options {
  buildDiscarder(logRotator(numToKeepStr: '32'))
 }

 stages {
  stage('Create Virtual Environment') {
   steps {
    cleanWs()
    make_venv python: defaults.python
    script {
     currentBuild.displayName = "# ${env.BUILD_NUMBER} ${env.BUILD_LABEL}"
    }
   }
  }
  stage('Source Variables from Config') {
   steps {
    configFileProvider([configFile(fileId: 'bc5f0cbc-616f-46de-bdfe-2e024e84fcbf', variable: 'CONFIG_FILES')]) {
     sh_venv 'source ${CONFIG_FILES}'
     load('config/sat6_repos_urls.groovy')
     script{
        RHEL7_SATELLITE_URL = "${params.RHEL7_SATELLITE_URL}" ?: "${SATELLITE6_RHEL7}"
        RHEL7_CAPSULE_URL = "${params.RHEL7_CAPSULE_URL}" ?: "${CAPSULE_RHEL7}"
        RHEL6_TOOLS_URL = "${params.RHEL6_TOOLS_URL}" ?: "${TOOLS_RHEL6}"
        RHEL7_TOOLS_URL = "${params.RHEL7_TOOLS_URL}" ?: "${TOOLS_RHEL7}"
        RHEL8_TOOLS_URL = "${params.RHEL8_TOOLS_URL}" ?: "${TOOLS_RHEL8}"
     }
    }
   }
  }
  stage('Trigger Downstream Builds') {
   parallel {
    stage("Trigger Provisioning job for rhel7") {
     steps {
      script {
       build job: "provisioning-${satellite_version}-rhel7",
        parameters: [
         string(name: 'BASE_URL', value: "${RHEL7_SATELLITE_URL}"),
         string(name: 'CAPSULE_URL', value: "${RHEL7_CAPSULE_URL}"),
         string(name: 'RHEL6_TOOLS_URL', value: "${RHEL6_TOOLS_URL}"),
         string(name: 'RHEL7_TOOLS_URL', value: "${RHEL7_TOOLS_URL}"),
         string(name: 'RHEL8_TOOLS_URL', value: "${RHEL8_TOOLS_URL}"),
         string(name: 'SELINUX_MODE', value: "${params.SELINUX_MODE}"),
         string(name: 'SATELLITE_DISTRIBUTION', value: "${params.SATELLITE_DISTRIBUTION}"),
         string(name: 'ROBOTTELO_WORKERS', value: "${params.ROBOTTELO_WORKERS}"),
         string(name: 'PROXY_MODE', value: "${params.PROXY_MODE}"),
         string(name: 'BUILD_LABEL', value: "${params.BUILD_LABEL}"),
         string(name: 'EXTERNAL_AUTH', value: "${params.EXTERNAL_AUTH}"),
         booleanParam(name: 'IDM_REALM', defaultValue: true, value: "${params.IDM_REALM}"),
         string(name: 'IMAGE', value: "${params.RHEL7_IMAGE}"),
         string(name: 'BROWSER', value: "${params.BROWSER}"),
         string(name: 'UI_PLATFORM', value: "${params.UI_PLATFORM}"),
         string(name: 'START_TIER', value: "${params.START_TIER}"),
        ],
        propagate: false,
        wait: true
      }
     }
    }
    stage("Trigger Polarion upgrade test Case job") {
     steps {
      script {
       build job: "polarion-upgrade-test-case",
        propagate: false,
        wait: true
      }
     }
    }
    stage("Trigger Sanity job for rhel7") {
     when {
      expression {
       ( !SATELLITE_VERSION.contains('upstream-nightly'))
      }
     }
     steps {
      build job: "satellite6-sanity-check-${satellite_version}-rhel7",
       parameters: [
        string(name: 'BASE_URL', value: "${RHEL7_SATELLITE_URL}"),
        string(name: 'SELINUX_MODE', value: "${params.SELINUX_MODE}"),
        string(name: 'SATELLITE_DISTRIBUTION', value: "${params.SATELLITE_DISTRIBUTION}"),
        string(name: 'PROXY_MODE', value: "${params.PROXY_MODE}"),
        string(name: 'BUILD_LABEL', value: "${params.BUILD_LABEL}"),
        string(name: 'EXTERNAL_AUTH', value: "${params.EXTERNAL_AUTH}"),
        booleanParam(name: 'IDM_REALM', defaultValue: true, value: "${params.IDM_REALM}"),
       ],
       propagate: false,
       wait: true
     }
    }
    stage("Trigger upgrade job for rhel7") {
     when {
      expression {
       ( !SATELLITE_VERSION.contains('upstream-nightly'))
      }
     }
     steps {
      build job: "upgrade-to-${satellite_version}-rhel7",
       parameters: [
        string(name: 'BUILD_LABEL', value: "${params.BUILD_LABEL}"),
        string(name: 'ROBOTTELO_WORKERS', value: "${params.ROBOTTELO_WORKERS}"),
       ],
       propagate: false,
       wait: true
     }
    }
    stage("Trigger upgrade cleanup job for rhel7") {
     when {
      expression {
       ( !SATELLITE_VERSION.contains('upstream-nightly'))
      }
     }
     steps {
      build job: "satellite6-upgrade-cleanup",
       propagate: false,
       wait: true
     }
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
}
}
