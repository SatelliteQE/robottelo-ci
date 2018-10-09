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

      // Work around for parameters not being accessible in functions
      writeFile file: 'snap_version', text: snapVersion
      def version = readFile 'snap_version'

      createLifecycleEnvironment {
          name = version
          prior = 'Library'
          organization = 'Sat6-CI'
      }

    }

    stage("Archive Satellite Maintenance") {

      // Work around for parameters not being accessible in functions
      writeFile file: 'snap_version', text: snapVersion
      def version = readFile 'snap_version'

      promoteContentView {
        organization = 'Sat6-CI'
        content_view = release_composite_content_view
        from_lifecycle_environment = 'QA'
        to_lifecycle_environment = version
      }

    }
}
