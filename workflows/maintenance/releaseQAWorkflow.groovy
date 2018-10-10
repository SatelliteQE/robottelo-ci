node('sat6-build') {
    stage("Setup Workspace") {

        deleteDir()
        setupAnsibleEnvironment {}
    }

    stage("Promote Satellite Maintenance to QA") {

        compareContentViews(
          organization: 'Sat6-CI',
          content_view: release_content_view,
          from_lifecycle_environment: 'Library',
          to_lifecycle_environment: 'QA'
        )

        promoteContentView(
          organization: 'Sat6-CI',
          content_view: release_content_view,
          from_lifecycle_environment: 'Library',
          to_lifecycle_environment: 'QA'
        )

        promoteContentView(
          organization: 'Sat6-CI',
          content_view: release_composite_content_view,
          from_lifecycle_environment: 'Library',
          to_lifecycle_environment: 'QA'
        )

    }

    stage("Create Archive Environment") {

      createLifecycleEnvironment(
          name: snapVersion,
          prior: 'Library',
          organization: 'Sat6-CI'
      )

    }

    stage("Archive Satellite Maintenance") {

      promoteContentView(
        organization: 'Sat6-CI',
        content_view: release_composite_content_view,
        from_lifecycle_environment: 'QA',
        to_lifecycle_environment: snapVersion
      )

    }
}
