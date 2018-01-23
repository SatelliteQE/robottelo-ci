#!/usr/bin/groovy


node('rhel') {
    snapperStage("Setup Workspace") {

        deleteDir()
        setupAnsibleEnvironment {}
    }

    snapperStage("Promote Satellite Maintenance to QA") {

        compareContentViews {
          organization = 'Sat6-CI'
          content_view = 'Satellite Maintenance RHEL7'
          from_lifecycle_environment = 'Library'
          to_lifecycle_environment = 'QA'
        }

        promoteContentView {
          organization = 'Sat6-CI'
          content_view = 'Satellite Maintenance RHEL7'
          from_lifecycle_environment = 'Library'
          to_lifecycle_environment = 'QA'
        }

    }
}
