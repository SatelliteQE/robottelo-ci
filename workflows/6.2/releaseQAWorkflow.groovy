#!/usr/bin/groovy

node('sat6-build') {
    stage("Setup Workspace") {

        deleteDir()
        setupAnsibleEnvironment {}

    }

    stage("Create Archive Environment") {

        // Remove old package report
        sh 'rm -rf package_report.yaml'

        createLifecycleEnvironment (
            name: previousSnapVersion,
            prior: 'Library',
            organization: 'Sat6-CI'
        )

    }

    stage("Archive Satellite") {

        promoteContentView (
          organization: 'Sat6-CI',
          content_view: 'Satellite 6.2 RHEL7',
          from_lifecycle_environment: 'QA',
          to_lifecycle_environment: previousSnapVersion
        )

        promoteContentView (
          organization: 'Sat6-CI',
          content_view: 'Satellite 6.2 RHEL6',
          from_lifecycle_environment: 'QA',
          to_lifecycle_environment: previousSnapVersion
        )
    }

    stage("Archive Capsule") {

        promoteContentView (
          organization: 'Sat6-CI',
          content_view: 'Capsule 6.2 RHEL7',
          from_lifecycle_environment: 'QA',
          to_lifecycle_environment: previousSnapVersion
        )

        promoteContentView (
          organization: 'Sat6-CI',
          content_view: 'Capsule 6.2 RHEL6',
          from_lifecycle_environment: 'QA',
          to_lifecycle_environment: previousSnapVersion
        )
    }

    stage("Archive Tools") {

        promoteContentView (
          organization: 'Sat6-CI',
          content_view: 'Tools 6.2 RHEL7',
          from_lifecycle_environment: 'QA',
          to_lifecycle_environment: previousSnapVersion
        )

        promoteContentView (
          organization: 'Sat6-CI',
          content_view: 'Tools 6.2 RHEL6',
          from_lifecycle_environment: 'QA',
          to_lifecycle_environment: previousSnapVersion
        )

        promoteContentView (
          organization: 'Sat6-CI',
          content_view: 'Tools 6.2 RHEL5',
          from_lifecycle_environment: 'QA',
          to_lifecycle_environment: previousSnapVersion
        )
    }

    stage("Promote Satellite to QA") {
        compareContentViews (
          organization: 'Sat6-CI',
          content_view: 'Satellite 6.2 RHEL7',
          from_lifecycle_environment: 'Library',
          to_lifecycle_environment: 'QA'
        )

        promoteContentView (
          organization: 'Sat6-CI',
          content_view: 'Satellite 6.2 RHEL7',
          from_lifecycle_environment: 'Library',
          to_lifecycle_environment: 'QA'
        )

        compareContentViews (
          organization: 'Sat6-CI',
          content_view: 'Satellite 6.2 RHEL6',
          from_lifecycle_environment: 'Library',
          to_lifecycle_environment: 'QA'
        )

        promoteContentView (
          organization: 'Sat6-CI',
          content_view: 'Satellite 6.2 RHEL6',
          from_lifecycle_environment: 'Library',
          to_lifecycle_environment: 'QA'
        )
    }

    stage("Promote Capsule to QA") {
        compareContentViews (
          organization: 'Sat6-CI',
          content_view: 'Capsule 6.2 RHEL7',
          from_lifecycle_environment: 'Library',
          to_lifecycle_environment: 'QA'
        )

        promoteContentView (
          organization: 'Sat6-CI',
          content_view: 'Capsule 6.2 RHEL7',
          from_lifecycle_environment: 'Library',
          to_lifecycle_environment: 'QA'
        )

        compareContentViews (
          organization: 'Sat6-CI',
          content_view: 'Capsule 6.2 RHEL6',
          from_lifecycle_environment: 'Library',
          to_lifecycle_environment: 'QA'
        )

        promoteContentView (
          organization: 'Sat6-CI',
          content_view: 'Capsule 6.2 RHEL6',
          from_lifecycle_environment: 'Library',
          to_lifecycle_environment: 'QA'
        )
    }

    stage("Promote Tools to QA") {
        compareContentViews (
          organization: 'Sat6-CI',
          content_view: 'Tools 6.2 RHEL7',
          from_lifecycle_environment: 'Library',
          to_lifecycle_environment: 'QA'
        )

        promoteContentView (
          organization: 'Sat6-CI',
          content_view: 'Tools 6.2 RHEL7',
          from_lifecycle_environment: 'Library',
          to_lifecycle_environment: 'QA'
        )

        compareContentViews (
          organization: 'Sat6-CI',
          content_view: 'Tools 6.2 RHEL6',
          from_lifecycle_environment: 'Library',
          to_lifecycle_environment: 'QA'
        )

        promoteContentView (
          organization: 'Sat6-CI',
          content_view: 'Tools 6.2 RHEL6',
          from_lifecycle_environment: 'Library',
          to_lifecycle_environment: 'QA'
        )

        compareContentViews (
          organization: 'Sat6-CI',
          content_view: 'Tools 6.2 RHEL5',
          from_lifecycle_environment: 'Library',
          to_lifecycle_environment: 'QA'
        )

        promoteContentView (
          organization: 'Sat6-CI',
          content_view: 'Tools 6.2 RHEL5',
          from_lifecycle_environment: 'Library',
          to_lifecycle_environment: 'QA'
        )
    }
}

node {
    stage("Run Automation") {
        build job: 'trigger-satellite-6.2', parameters: [
          [$class: 'StringParameterValue', name: 'SATELLITE_DISTRIBUTION', value: 'INTERNAL'],
          [$class: 'StringParameterValue', name: 'BUILD_LABEL', value: "Satellite ${snapVersion}"],
        ]

    }
}
