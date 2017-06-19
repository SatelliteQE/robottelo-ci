#!/usr/bin/groovy

import groovy.json.JsonSlurper


stage("Promote Satellite Maintenance to QA") {
    node('rhel') {

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
