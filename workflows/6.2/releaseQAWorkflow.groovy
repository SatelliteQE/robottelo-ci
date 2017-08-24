#!/usr/bin/groovy

import groovy.json.JsonSlurper


node('rhel') {
    snapperStage("Create Archive Environment") {

        // Remove old package report
        sh 'rm -rf package_report.yaml'

        // Work around for parameters not being accessible in functions
        writeFile file: 'previous_snap', text: previousSnapVersion
        def version = readFile 'previous_snap'

        createLifecycleEnvironment {
            name = version
            prior = 'Library'
            organization = 'Sat6-CI'
        }

    }

    snapperStage("Archive Satellite") {

        def versionInArchive = null

        // Work around for parameters not being accessible in functions
        writeFile file: 'previous_snap', text: previousSnapVersion
        def version = readFile 'previous_snap'

        promoteContentView {
          organization = 'Sat6-CI'
          content_view = 'Satellite 6.2 RHEL7'
          from_lifecycle_environment = 'QA'
          to_lifecycle_environment = version
        }

        promoteContentView {
          organization = 'Sat6-CI'
          content_view = 'Satellite 6.2 RHEL6'
          from_lifecycle_environment = 'QA'
          to_lifecycle_environment = version
        }
    }

    snapperStage("Archive Capsule") {

        // Work around for parameters not being accessible in functions
        writeFile file: 'previous_snap', text: previousSnapVersion
        def version = readFile 'previous_snap'

        promoteContentView {
          organization = 'Sat6-CI'
          content_view = 'Capsule 6.2 RHEL7'
          from_lifecycle_environment = 'QA'
          to_lifecycle_environment = version
        }

        promoteContentView {
          organization = 'Sat6-CI'
          content_view = 'Capsule 6.2 RHEL6'
          from_lifecycle_environment = 'QA'
          to_lifecycle_environment = version
        }
    }

    snapperStage("Archive Tools") {
        // Work around for parameters not being accessible in functions
        writeFile file: 'previous_snap', text: previousSnapVersion
        def version = readFile 'previous_snap'

        promoteContentView {
          organization = 'Sat6-CI'
          content_view = 'Tools 6.2 RHEL7'
          from_lifecycle_environment = 'QA'
          to_lifecycle_environment = version
        }

        promoteContentView {
          organization = 'Sat6-CI'
          content_view = 'Tools 6.2 RHEL6'
          from_lifecycle_environment = 'QA'
          to_lifecycle_environment = version
        }

        promoteContentView {
          organization = 'Sat6-CI'
          content_view = 'Tools 6.2 RHEL5'
          from_lifecycle_environment = 'QA'
          to_lifecycle_environment = version
        }
    }

    snapperStage("Promote Satellite to QA") {
        compareContentViews {
          organization = 'Sat6-CI'
          content_view = 'Satellite 6.2 RHEL7'
          from_lifecycle_environment = 'Library'
          to_lifecycle_environment = 'QA'
        }

        promoteContentView {
          organization = 'Sat6-CI'
          content_view = 'Satellite 6.2 RHEL7'
          from_lifecycle_environment = 'Library'
          to_lifecycle_environment = 'QA'
        }

        compareContentViews {
          organization = 'Sat6-CI'
          content_view = 'Satellite 6.2 RHEL6'
          from_lifecycle_environment = 'Library'
          to_lifecycle_environment = 'QA'
        }

        promoteContentView {
          organization = 'Sat6-CI'
          content_view = 'Satellite 6.2 RHEL6'
          from_lifecycle_environment = 'Library'
          to_lifecycle_environment = 'QA'
        }
    }

    snapperStage("Promote Capsule to QA") {
        compareContentViews {
          organization = 'Sat6-CI'
          content_view = 'Capsule 6.2 RHEL7'
          from_lifecycle_environment = 'Library'
          to_lifecycle_environment = 'QA'
        }

        promoteContentView {
          organization = 'Sat6-CI'
          content_view = 'Capsule 6.2 RHEL7'
          from_lifecycle_environment = 'Library'
          to_lifecycle_environment = 'QA'
        }

        compareContentViews {
          organization = 'Sat6-CI'
          content_view = 'Capsule 6.2 RHEL6'
          from_lifecycle_environment = 'Library'
          to_lifecycle_environment = 'QA'
        }

        promoteContentView {
          organization = 'Sat6-CI'
          content_view = 'Capsule 6.2 RHEL6'
          from_lifecycle_environment = 'Library'
          to_lifecycle_environment = 'QA'
        }
    }

    snapperStage("Promote Tools to QA") {
        compareContentViews {
          organization = 'Sat6-CI'
          content_view = 'Tools 6.2 RHEL7'
          from_lifecycle_environment = 'Library'
          to_lifecycle_environment = 'QA'
        }

        promoteContentView {
          organization = 'Sat6-CI'
          content_view = 'Tools 6.2 RHEL7'
          from_lifecycle_environment = 'Library'
          to_lifecycle_environment = 'QA'
        }

        compareContentViews {
          organization = 'Sat6-CI'
          content_view = 'Tools 6.2 RHEL6'
          from_lifecycle_environment = 'Library'
          to_lifecycle_environment = 'QA'
        }

        promoteContentView {
          organization = 'Sat6-CI'
          content_view = 'Tools 6.2 RHEL6'
          from_lifecycle_environment = 'Library'
          to_lifecycle_environment = 'QA'
        }

        compareContentViews {
          organization = 'Sat6-CI'
          content_view = 'Tools 6.2 RHEL5'
          from_lifecycle_environment = 'Library'
          to_lifecycle_environment = 'QA'
        }

        promoteContentView {
          organization = 'Sat6-CI'
          content_view = 'Tools 6.2 RHEL5'
          from_lifecycle_environment = 'Library'
          to_lifecycle_environment = 'QA'
        }
    }
}

node {
    snapperStage("Run Automation") {
        build job: 'trigger-satellite-6.2', parameters: [
          [$class: 'StringParameterValue', name: 'SATELLITE_DISTRIBUTION', value: 'INTERNAL'],
          [$class: 'StringParameterValue', name: 'BUILD_LABEL', value: "Satellite ${snapVersion}"],
        ]

    }
}
