// Library Methods

def copyActivationKey(args) {

    runPlaybook {
      playbook = 'playbooks/copy_activation_key.yml'
      extraVars = [
          'activation_key_name': args.activation_key,
          'organization': args.organization,
          'lifecycle_environment': args.lifecycle_environment,
      ]
    }

}

def promoteContentView(args) {

    runPlaybook {
      playbook = 'playbooks/promote_content_view.yml'
      extraVars = [
          'content_view_name': args.content_view,
          'organization': args.organization,
          'to_lifecycle_environment': args.to_lifecycle_environment,
          'from_lifecycle_environment': args.from_lifecycle_environment,
      ]
    }
}

def createLifecycleEnvironment(args) {

    runPlaybook {
      playbook = 'playbooks/create_lifecycle_environment.yml'
      extraVars = [
          'lifecycle_environment_name': args.name,
          'organization': args.organization,
          'prior': args.prior,
      ]
    }
}

def compareContentViews(args) {

    def archive_file = 'package_report.yaml'

    toolBelt(
        command: 'release compare-content-view',
        options: [
            "--content-view '${args.content_view}'",
            "--from-environment '${args.from_lifecycle_environment}'",
            "--to-environment '${args.to_lifecycle_environment}'",
            "--output '${archive_file}'"
        ],
        archive_file: archive_file
    )

}

def generateSnapVersion(args) {

    def full_snap_version

    if (args.snap_version) {
        full_snap_version = "${args.release_name}-${args.snap_version}"
    } else {
        def response = httpRequest url: "${OHSNAP_URL}/api/releases/${args.release_name}/snaps/new"
        def snap_data = readJSON text: response.content
        full_snap_version = "${args.release_name}-${snap_data['version']}"
    }

    return full_snap_version

}
