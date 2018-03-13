#!/usr/bin/groovy

node('rhel') {
    stage("Setup Workspace") {

        deleteDir()
        setupAnsibleEnvironment {}

    }

    stage("Create Archive Environment") {

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

    stage("Archive Satellite") {

        def versionInArchive = null

        // Work around for parameters not being accessible in functions
        writeFile file: 'previous_snap', text: previousSnapVersion
        def version = readFile 'previous_snap'

        satellite_composite_content_views.each { cv ->
          promoteContentView {
            organization = 'Sat6-CI'
            content_view = cv
            from_lifecycle_environment = 'QA'
            to_lifecycle_environment = version
          }
        }
    }

    stage("Archive Capsule") {

        // Work around for parameters not being accessible in functions
        writeFile file: 'previous_snap', text: previousSnapVersion
        def version = readFile 'previous_snap'

        capsule_composite_content_views.each { cv ->
          promoteContentView {
            organization = 'Sat6-CI'
            content_view = cv
            from_lifecycle_environment = 'QA'
            to_lifecycle_environment = version
          }
        }
    }

    stage("Archive Tools") {

        // Work around for parameters not being accessible in functions
        writeFile file: 'previous_snap', text: previousSnapVersion
        def version = readFile 'previous_snap'

        tools_composite_content_views.each { cv ->
          promoteContentView {
            organization = 'Sat6-CI'
            content_view = cv
            from_lifecycle_environment = 'QA'
            to_lifecycle_environment = version
          }
        }

    }

    stage("Promote Satellite to QA") {

      satellite_composite_content_views.each { cv ->
        compareContentViews {
          organization = 'Sat6-CI'
          content_view = cv
          from_lifecycle_environment = 'Library'
          to_lifecycle_environment = 'QA'
        }

        promoteContentView {
          organization = 'Sat6-CI'
          content_view = cv
          from_lifecycle_environment = 'Library'
          to_lifecycle_environment = 'QA'
        }
      }
    }

    stage("Promote Capsule to QA") {

      capsule_composite_content_views.each { cv ->
        compareContentViews {
          organization = 'Sat6-CI'
          content_view = cv
          from_lifecycle_environment = 'Library'
          to_lifecycle_environment = 'QA'
        }

        promoteContentView {
          organization = 'Sat6-CI'
          content_view = cv
          from_lifecycle_environment = 'Library'
          to_lifecycle_environment = 'QA'
        }
      }
    }

    stage("Promote Tools to QA") {

      tools_composite_content_views.each { cv ->
        compareContentViews {
          organization = 'Sat6-CI'
          content_view = cv
          from_lifecycle_environment = 'Library'
          to_lifecycle_environment = 'QA'
        }

        promoteContentView {
          organization = 'Sat6-CI'
          content_view = cv
          from_lifecycle_environment = 'Library'
          to_lifecycle_environment = 'QA'
        }
      }

    }
}

node {
    stage("Run Automation") {
        build job: "trigger-satellite-${satellite_main_version}", parameters: [
          [$class: 'StringParameterValue', name: 'SATELLITE_DISTRIBUTION', value: 'INTERNAL'],
          [$class: 'StringParameterValue', name: 'BUILD_LABEL', value: "Satellite ${snapVersion}"],
        ]
    }
}
