node('sat6-build') {

    stage("Setup Workspace") {

        setupAnsibleEnvironment {}

    }

    stage("Generate Composes") {

        def compose_git_repo = env.COMPOSE_GIT_REPOSITORY ?: ''

        runDownstreamPlaybook {
            playbook = 'playbooks/clone_compose_repo.yml'
            extraVars = [
                'compose_git_repo': compose_git_repo
            ]
        }

        runPlaybookInParallel {
            name = "compose-rhel"
            items = compose_versions
            item_name = 'rhel_version'
            playbook = 'playbooks/build_compose.yml'
            extraVars = [
                'compose_git_repo': compose_git_repo,
                'compose_version': 'sat-maintenance-6',
                'compose_label': compose_label,
                'compose_name': 'satellite-maintenance-6',
                'compose_tag': compose_tag
            ]
        }

    }

    stage("Test Installation") {

        test_forklift(
            os_versions: os_versions,
            satellite_product: satellite_product,
            satellite_version: satellite_version
        )

    }

    stage("Sync Repositories") {

        runPlaybookInParallel {
            name = "sync"
            items = maintenance_repositories
            item_name = 'repository'
            extraVars = ["product": maintenance_product]
            playbook = 'playbooks/sync_repositories.yml'
        }

    }

    stage("Publish Content Views") {

        runPlaybookInParallel {
            name = "publish"
            items = content_views
            item_name = 'content_view'
            playbook = 'playbooks/publish_content_views.yml'
        }

    }

    stage("Publish Composite Content Views") {
      runPlaybookSequentially {
          items = composite_content_views
          item_name = 'content_view'
          playbook = 'playbooks/publish_content_views.yml'
      }
    }
}
