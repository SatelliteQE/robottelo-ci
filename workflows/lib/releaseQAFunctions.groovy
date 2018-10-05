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

def compareContentViews(body) {

    def config = [:]
    body.resolveStrategy = Closure.DELEGATE_FIRST
    body.delegate = config
    body()

    def archive_file = 'package_report.yaml'

    toolBelt(
        command: 'release compare-content-view',
        options: [
            "--content-view '${config.content_view}'",
            "--from-environment '${config.from_lifecycle_environment}'",
            "--to-environment '${config.to_lifecycle_environment}'",
            "--output '${archive_file}'"
        ]
    )

    archive "tool_belt/${archive_file}"
}
