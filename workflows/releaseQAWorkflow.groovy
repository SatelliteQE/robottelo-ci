node('sat6-build') {
    stage("Setup Workspace") {

        deleteDir()
        setupAnsibleEnvironment {}

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

    stage("Create Archive Environment") {

      createLifecycleEnvironment (
          name: snapVersion,
          prior: 'Library',
          organization: 'Sat6-CI'
      )

    }

    stage("Archive Satellite") {

      // Work around for parameters not being accessible in functions
      writeFile file: 'snap_version', text: snapVersion
      def version = readFile 'snap_version'

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
      writeFile file: 'snap_version', text: snapVersion
      def version = readFile 'snap_version'

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
      writeFile file: 'snap_version', text: snapVersion
      def version = readFile 'snap_version'

      tools_composite_content_views.each { cv ->
        promoteContentView {
          organization = 'Sat6-CI'
          content_view = cv
          from_lifecycle_environment = 'QA'
          to_lifecycle_environment = version
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
