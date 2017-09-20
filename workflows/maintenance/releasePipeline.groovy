def compose_versions = ['7']
def os_versions = ['7']
def satellite_version = 'maintenance'
def products = [
    'Satellite Maintenance Composes'
]
def content_views = [
    'Satellite Maintenance RHEL7'
]


node('sat6-rhel7') {

    stage("Setup Workspace") {

        setupAnsibleEnvironment {}

    }

    stage("Generate Composes") {

        def compose_git_repo = env.COMPOSE_GIT_REPOSITORY ?: ''

        runPlaybook {
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
                'compose_label': 'SatMaintenance-6',
                'compose_name': 'satellite-maintenance-6'
            ]
        }

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
