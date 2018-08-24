#!/usr/bin/groovy


node('sat6-build') {
    stage("Setup Workspace") {

        deleteDir()
        setupAnsibleEnvironment {}
    }

    stage("Promote Satellite Maintenance to QA") {

        compareContentViews {
          organization = 'Sat6-CI'
          content_view = content_view
          from_lifecycle_environment = 'Library'
          to_lifecycle_environment = 'QA'
        }

        promoteContentView {
          organization = 'Sat6-CI'
          content_view = content_view
          from_lifecycle_environment = 'Library'
          to_lifecycle_environment = 'QA'
        }

        promoteContentView {
          organization = 'Sat6-CI'
          content_view = composite_content_view
          from_lifecycle_environment = 'Library'
          to_lifecycle_environment = 'QA'
        }

    }
}
