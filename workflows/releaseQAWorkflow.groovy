def snap_version = generateSnapVersion(release_name: releaseVersion, snap_version: snapVersion)
def full_snap_version = "${releaseVersion}-${snap_version}"

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

      tools_sles_content_views.each { cv ->
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
          name: full_snap_version,
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
          to_lifecycle_environment: full_snap_version
        )
      }

      satellite_activation_keys.each { ak ->
        copyActivationKey(
          organization: 'Sat6-CI',
          activation_key: ak,
          lifecycle_environment: full_snap_version
        )
      }

    }

    stage("Archive Capsule") {

      capsule_composite_content_views.each { cv ->
        promoteContentView(
          organization: 'Sat6-CI',
          content_view: cv,
          from_lifecycle_environment: 'QA',
          to_lifecycle_environment: full_snap_version
        )
      }

      capsule_activation_keys.each { ak ->
        copyActivationKey(
          organization: 'Sat6-CI',
          activation_key: ak,
          lifecycle_environment: full_snap_version
        )
      }

    }

    stage("Archive Tools") {

      tools_composite_content_views.each { cv ->
        promoteContentView(
          organization: 'Sat6-CI',
          content_view: cv,
          from_lifecycle_environment: 'QA',
          to_lifecycle_environment: full_snap_version
        )
      }

      tools_sles_content_views.each { cv ->
        promoteContentView(
          organization: 'Sat6-CI',
          content_view: cv,
          from_lifecycle_environment: 'QA',
          to_lifecycle_environment: full_snap_version
        )
      }

      tools_activation_keys.each { ak ->
        copyActivationKey(
          organization: 'Sat6-CI',
          activation_key: ak,
          lifecycle_environment: full_snap_version
        )
      }

    }

    stage("Compute Dependencies") {
        generate_dependencies(
            satellite_version: satellite_main_version,
            source: "qa"
        )
    }

}

node {
    stage("Run Automation") {
      if (satellite_product == 'satellite') {
        script {
          try{
            timeout(10) {
                sendCIMessage messageProperties: '',
                    failOnError: false,
                    providerName: 'Satellite UMB',
                    overrides: [topic: 'VirtualTopic.eng.sat6eng-ci.snap.ready'],
                    messageContent: "{'satellite_version': '${releaseVersion}', 'snap_version': '${snap_version}', 'rhel_major_version': '7', 'satellite_activation_key': 'satellite-${satellite_main_version}-qa-rhel7-${full_snap_version}', 'capsule_activation_key': 'capsule-${satellite_main_version}-qa-rhel7-${full_snap_version}'}",
                    messageType: 'Custom'
            }
          } catch (err) {
            echo "UMB message failed"
            echo err
          }
        }
      }
    }
}

node('sat6-build') {
    stage("Finish release") {
      if (autoreleaseEnabled) {

        release_snap(
          release_name: 'satellite',
          release_version: releaseVersion,
          snap_version: snap_version,
          release_stream: satellite_main_version
        )
      }
    }
}
