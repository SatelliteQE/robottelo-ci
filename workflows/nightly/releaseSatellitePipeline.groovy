node('sat6-build') {

    stage("Setup Workspace") {

        setupAnsibleEnvironment {}

    }

    stage("Generate Composes") {

        def compose_git_repo = env.COMPOSE_GIT_REPOSITORY ?: ''

        runDownstreamPlaybook {
            playbook = 'playbooks/update_packaging_repo.yml'
            extraVars = [
                'git_server': git_hostname,
                'git_group': 'satellite6',
                'satellite_version': satellite_version
            ]
        }

        runPlaybookInParallel {
            name = "compose-rhel"
            items = compose_versions
            item_name = 'rhel_version'
            playbook = 'playbooks/generate_compose.yml'
        }

    }

    stage("Test Installation") {

        test_forklift(
            os_versions: os_versions,
            satellite_product: satellite_product,
            satellite_version: satellite_main_version
        )

    }


    stage("Sync Repositories") {

        runPlaybookInParallel {
            name = "sync"
            items = products
            item_name = 'product'
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
}
