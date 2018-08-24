def snap_version = generateSnapVersion(release_name: satellite_version, snap_version: snapVersion)

node('sat6-build') {
    stage("Setup Workspace") {

        deleteDir()
        setupAnsibleEnvironment {}
    }

    stage("Promote Satellite Maintenance to QA") {

      content_views.each { cv ->
        compareContentViews(
          organization: 'Sat6-CI',
          content_view: cv,
          from_lifecycle_environment: 'Library',
          to_lifecycle_environment: 'QA'
        )

        promoteContentView(
          organization: 'Sat6-CI',
          content_view: cv,
          from_lifecycle_environment: 'Library',
          to_lifecycle_environment: 'QA'
        )
      }

      composite_content_views.each { cv ->
        promoteContentView(
          organization: 'Sat6-CI',
          content_view: cv,
          from_lifecycle_environment: 'Library',
          to_lifecycle_environment: 'QA'
        )
      }

    }

    stage("Create Archive Environment") {

      createLifecycleEnvironment(
          name: snap_version,
          prior: 'Library',
          organization: 'Sat6-CI'
      )

    }

    stage("Archive Satellite Maintenance") {

      composite_content_views.each { cv ->
        promoteContentView(
          organization: 'Sat6-CI',
          content_view: cv,
          from_lifecycle_environment: 'QA',
          to_lifecycle_environment: snap_version
        )
      }

    }

    stage("Release SNAP") {
        when {
            expression { autorelease_enabled }
        }

        steps {
            release_snap(
                release_name: release_name,
                release_version: release_version,
                snap_version: snap_version
            )
        }
    }
}
