def snap_version = generateSnapVersion(release_name: releaseVersion, snap_version: snapVersion)

node('sat6-build') {
    stage("Setup Workspace") {

        deleteDir()
        setupAnsibleEnvironment {}

    }

    stage("Promote Satellite to QA") {

      satellite_composite_content_views.each { cv ->
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
    }

    stage("Promote Capsule to QA") {

      capsule_composite_content_views.each { cv ->
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
    }

    stage("Promote Tools to QA") {

      tools_composite_content_views.each { cv ->
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

    }

    stage("Create Archive Environment") {

      createLifecycleEnvironment(
          name: snap_version,
          prior: 'Library',
          organization: 'Sat6-CI'
      )

    }

    stage("Archive Satellite") {

      satellite_composite_content_views.each { cv ->
        promoteContentView(
          organization: 'Sat6-CI',
          content_view: cv,
          from_lifecycle_environment: 'QA',
          to_lifecycle_environment: snap_version
        )
      }

      satellite_activation_keys.each { ak ->
        copyActivationKey(
          organization: 'Sat6-CI',
          activation_key: ak,
          lifecycle_environment: snap_version
        )
      }

    }

    stage("Archive Capsule") {

      capsule_composite_content_views.each { cv ->
        promoteContentView(
          organization: 'Sat6-CI',
          content_view: cv,
          from_lifecycle_environment: 'QA',
          to_lifecycle_environment: snap_version
        )
      }

      capsule_activation_keys.each { ak ->
        copyActivationKey(
          organization: 'Sat6-CI',
          activation_key: ak,
          lifecycle_environment: snap_version
        )
      }

    }

    stage("Archive Tools") {

      tools_composite_content_views.each { cv ->
        promoteContentView(
          organization: 'Sat6-CI',
          content_view: cv,
          from_lifecycle_environment: 'QA',
          to_lifecycle_environment: snap_version
        )
      }

      tools_activation_keys.each { ak ->
        copyActivationKey(
          organization: 'Sat6-CI',
          activation_key: ak,
          lifecycle_environment: snap_version
        )
      }

    }

}

node {
    stages {
        stage("Run Automation") {
            parallel {
                stage("Trigger downstream automation") {
                  build job: "trigger-satellite-${satellite_main_version}", parameters: [
                    [$class: 'StringParameterValue', name: 'SATELLITE_DISTRIBUTION', value: 'INTERNAL'],
                    [$class: 'StringParameterValue', name: 'BUILD_LABEL', value: "Satellite ${snap_version}"],
                  ]
                }

                stage("Trigger OSP snap image build") {
                  os_versions.each { os_ver ->
                    build job: "satellite6-osp-snap-image", parameters: [
        		      [$class: 'StringParameterValue', name: 'IMAGE', value: "5minute-RHEL${os_ver}"],
        		      [$class: 'StringParameterValue', name: 'RHEL_VERSION', value: "${os_ver}"],
        		      [$class: 'StringParameterValue', name: 'SAT_RELEASE', value: "${snap_version}"],
		            ]
		          }
                }
            }
        }
    }
}
