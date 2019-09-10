def snap_version = generateSnapVersion(release_name: satellite_version, snap_version: snapVersion)

pipeline {

    agent { label 'sat6-build' }

    options {
      ansiColor('xterm')
      disableConcurrentBuilds()
      timestamps()
    }

    stages {
      stage("Setup Workspace") {
        steps {
          deleteDir()
          setupAnsibleEnvironment {}
        }
      }

      stage("Promote Satellite Maintenance to QA") {
        steps {
          script {
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
        }
      }

      stage("Create Archive Environment") {
        steps {
          createLifecycleEnvironment(
              name: snap_version,
              prior: 'Library',
              organization: 'Sat6-CI'
          )
        }
      }

      stage("Archive Satellite Maintenance") {
        steps {
          script {
            composite_content_views.each { cv ->
              promoteContentView(
                organization: 'Sat6-CI',
                content_view: cv,
                from_lifecycle_environment: 'QA',
                to_lifecycle_environment: snap_version
              )
            }
          }
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
            snap_version: snap_version,
            release_stream: satellite_main_version
          )
        }
      }
    }
}
