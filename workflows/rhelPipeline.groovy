node('rhel') {

    snapperStage("Setup Workspace") {

        deleteDir()
        setupAnsibleEnvironment {}

    }

    snapperStage("Sync Repositories") {
        def products = [
            'Red Hat Enterprise Linux Server',
            'Red Hat Software Collections for RHEL Server'
        ]

        runPlaybookInParallel {
            name = "sync"
            items = products
            item_name = 'product'
            playbook = 'playbooks/sync_repositories.yml'
        }
    }

    snapperStage("Publish Content Views") {
        def content_views = [
            'RHEL6',
            'RHEL7'
        ]

        runPlaybookInParallel {
            name = "publish"
            items = content_views
            item_name = 'content_view'
            playbook = 'playbooks/publish_content_views.yml'
        }
    }
}
