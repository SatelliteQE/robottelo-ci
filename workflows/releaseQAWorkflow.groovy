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

        promoteContentView (
          organization: 'Sat6-CI',
          content_view: cv,
          from_lifecycle_environment: 'Library',
          to_lifecycle_environment: 'QA'
        )
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

        promoteContentView (
          organization: 'Sat6-CI',
          content_view: cv,
          from_lifecycle_environment: 'Library',
          to_lifecycle_environment: 'QA'
        )
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

        promoteContentView (
          organization: 'Sat6-CI',
          content_view: cv,
          from_lifecycle_environment: 'Library',
          to_lifecycle_environment: 'QA'
        )
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

      satellite_composite_content_views.each { cv ->
        promoteContentView (
          organization: 'Sat6-CI',
          content_view: cv,
          from_lifecycle_environment: 'QA',
          to_lifecycle_environment: snapVersion
        )
      }

    }

    stage("Archive Capsule") {

      capsule_composite_content_views.each { cv ->
        promoteContentView (
          organization: 'Sat6-CI',
          content_view: cv,
          from_lifecycle_environment: 'QA',
          to_lifecycle_environment: snapVersion
        )
      }

    }

    stage("Archive Tools") {

      tools_composite_content_views.each { cv ->
        promoteContentView (
          organization: 'Sat6-CI',
          content_view: cv,
          from_lifecycle_environment: 'QA',
          to_lifecycle_environment: snapVersion
        )
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
