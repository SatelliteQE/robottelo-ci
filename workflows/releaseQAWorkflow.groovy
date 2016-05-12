#!/usr/bin/groovy

import groovy.json.JsonSlurper

stage "Compute Package Changes"
node('rhel') {

    def versionInTest = findContentView {
      organization = 'Sat6-CI'
      content_view = 'Satellite RHEL7'
      lifecycle_environment = 'Test'
    }

    def versionInQA = findContentView {
      organization = 'Sat6-CI'
      content_view = 'Satellite RHEL7'
      lifecycle_environment = 'QA'
    }
 
    echo versionInTest.toString()
    echo versionInQA.toString()
   
    if (versionInTest != versionInQA && versionInTest != null && versionInQA != null) {

        computePackageDifference {
          organization = 'Sat6-CI'
          content_view = 'Satellite RHEL7'
          from_environment = 'Test'
          to_environment = 'QA'
        }

    } else {

        echo "Version already promoted, no package changes calculated"

    }

}

stage "Create Archive Environment"
node('rhel') {

    // Work around for parameters not being accessible in functions
    writeFile file: 'previous_snap', text: previousSnapVersion
    def version = readFile 'previous_snap'

    createLifecycleEnvironment {
        name = version
        prior = 'Library'
        organization = 'Sat6-CI' 
    }

}

stage "Archive Satellite"
node('rhel') {

    // Work around for parameters not being accessible in functions
    writeFile file: 'previous_snap', text: previousSnapVersion
    def version = readFile 'previous_snap'

    promoteContentView {
      organization = 'Sat6-CI'
      content_view = 'Satellite RHEL7'
      from_lifecycle_environment = 'QA'
      to_lifecycle_environment = version
    }

    promoteContentView {
      organization = 'Sat6-CI'
      content_view = 'Satellite RHEL6'
      from_lifecycle_environment = 'QA'
      to_lifecycle_environment = version
    }

}

stage "Archive Capsule"
node('rhel') {

    // Work around for parameters not being accessible in functions
    writeFile file: 'previous_snap', text: previousSnapVersion
    def version = readFile 'previous_snap'

    promoteContentView {
      organization = 'Sat6-CI'
      content_view = 'Capsule RHEL7'
      from_lifecycle_environment = 'QA'
      to_lifecycle_environment = version
    }

    promoteContentView {
      organization = 'Sat6-CI'
      content_view = 'Capsule RHEL6'
      from_lifecycle_environment = 'QA'
      to_lifecycle_environment = version
    }

}

stage "Archive Tools"
node('rhel') {

    // Work around for parameters not being accessible in functions
    writeFile file: 'previous_snap', text: previousSnapVersion
    def version = readFile 'previous_snap'

    promoteContentView {
      organization = 'Sat6-CI'
      content_view = 'Tools RHEL7'
      from_lifecycle_environment = 'QA'
      to_lifecycle_environment = version
    }

    promoteContentView {
      organization = 'Sat6-CI'
      content_view = 'Tools RHEL6'
      from_lifecycle_environment = 'QA'
      to_lifecycle_environment = version
    }

    promoteContentView {
      organization = 'Sat6-CI'
      content_view = 'Tools RHEL5'
      from_lifecycle_environment = 'QA'
      to_lifecycle_environment = version
    }

}

stage "Promote Satellite to QA"
node('rhel') {

    promoteContentView {
      organization = 'Sat6-CI'
      content_view = 'Satellite RHEL7'
      from_lifecycle_environment = 'Test'
      to_lifecycle_environment = 'QA'
    }

    promoteContentView {
      organization = 'Sat6-CI'
      content_view = 'Satellite RHEL6'
      from_lifecycle_environment = 'Test'
      to_lifecycle_environment = 'QA'
    }

}

stage "Promote Capsule to QA"
node('rhel') {

    promoteContentView {
      organization = 'Sat6-CI'
      content_view = 'Capsule RHEL7'
      from_lifecycle_environment = 'Test'
      to_lifecycle_environment = 'QA'
    }

    promoteContentView {
      organization = 'Sat6-CI'
      content_view = 'Capsule RHEL6'
      from_lifecycle_environment = 'Test'
      to_lifecycle_environment = 'QA'
    }

}

stage "Promote Tools to QA"
node('rhel') {

    promoteContentView {
      organization = 'Sat6-CI'
      content_view = 'Tools RHEL7'
      from_lifecycle_environment = 'Library'
      to_lifecycle_environment = 'QA'
    }

    promoteContentView {
      organization = 'Sat6-CI'
      content_view = 'Tools RHEL6'
      from_lifecycle_environment = 'Library'
      to_lifecycle_environment = 'QA'
    }

    promoteContentView {
      organization = 'Sat6-CI'
      content_view = 'Tools RHEL5'
      from_lifecycle_environment = 'Library'
      to_lifecycle_environment = 'QA'
    }

}

stage "Run Automation"
node {

  build job: 'satellite6-downstream-trigger', parameters: [
    [$class: 'StringParameterValue', name: 'RHEL6_SATELLITE_URL', value: ''],
    [$class: 'StringParameterValue', name: 'RHEL6_CAPSULE_URL', value: ''],
    [$class: 'StringParameterValue', name: 'RHEL6_TOOLS_URL', value: ''],
    [$class: 'StringParameterValue', name: 'RHEL7_SATELLITE_URL', value: ''],
    [$class: 'StringParameterValue', name: 'RHEL7_CAPSULE_URL', value: ''],
    [$class: 'StringParameterValue', name: 'RHEL7_TOOLS_URL', value: ''],
    [$class: 'StringParameterValue', name: 'SATELLITE_VERSION', value: '6.2'],
    [$class: 'StringParameterValue', name: 'SELINUX_MODE', value: 'enforcing'],
    [$class: 'StringParameterValue', name: 'BUILD_LABEL', value: "Sat6.2.0-${snapVersion}"],
    [$class: 'StringParameterValue', name: 'UPGRADE_FROM', value: '6.1'],
    [$class: 'StringParameterValue', name: 'COMPOSE', value: '']
  ]

}

// Library Methods

def promoteContentView(body) {

    def config = [:]
    body.resolveStrategy = Closure.DELEGATE_FIRST
    body.delegate = config
    body()

    withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'artefact-satellite-credentials', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME']]) {
        
        def cmd = [
          "hammer --username ${env.USERNAME} --password ${env.PASSWORD} --server ${env.SATELLITE_SERVER}",
          "content-view version promote",
          "--organization '${config.organization}'",
          "--content-view '${config.content_view}'",
          "--to-lifecycle-environment '${config.to_lifecycle_environment}'",
          "--from-lifecycle-environment ${config.from_lifecycle_environment}",
          "--force"
        ]

        sh "${cmd.join(' ')}"
    }

}

def findContentView(body) {

    def config = [:]
    body.resolveStrategy = Closure.DELEGATE_FIRST
    body.delegate = config
    body()

    withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'artefact-satellite-credentials', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME']]) {
        
        def cmd = [
          "hammer --output json --username ${env.USERNAME} --password ${env.PASSWORD} --server ${env.SATELLITE_SERVER}",
          "content-view version list",
          "--organization '${config.organization}'",
          "--environment '${config.lifecycle_environment}'",
          "--content-view '${config.content_view}'"
        ]

        sh "${cmd.join(' ')} > versions.json"
        
        def versions = readFile "versions.json"
        versions = new JsonSlurper().parseText(versions)

        if (versions.length() == 0) {
            return null;
        } else {
            return versions.first()['ID'];
        }
    }
}

def computePackageDifference(body) {

    def config = [:]
    body.resolveStrategy = Closure.DELEGATE_FIRST
    body.delegate = config
    body()

    withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'artefact-satellite-credentials', passwordVariable: 'SATELLITE_PASSWORD', usernameVariable: 'SATELLITE_USERNAME']]) {

      git url: "https://github.com/ehelms/robottelo-ci.git", branch: 'workflow'
      dir("scripts") {
        env.organization = config.organization
        env.content_view_name = config.content_view
        env.lifecycle_environment = config.to_environment
        env.from_lifecycle_environment = config.from_environment

        sh "./build_config_file.rb"
        sh "./compare_content_views.rb"
        archive 'package_report.yaml'

      }

    }
}

def createLifecycleEnvironment(body) {

    def config = [:]
    body.resolveStrategy = Closure.DELEGATE_FIRST
    body.delegate = config
    body()

    withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'artefact-satellite-credentials', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME']]) {

        def cmd = [
            "hammer --output json",
            "--username ${env.USERNAME}",
            "--password ${env.PASSWORD}",
            "--server ${env.SATELLITE_SERVER}",
            "lifecycle-environment create",
            "--organization '${config.organization}'",
            "--name '${config.name}'",
            "--prior '${config.prior}'"
        ]

        sh "${cmd.join(' ')}"
    }       
}
