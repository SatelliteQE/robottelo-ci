node('sat6-build') {

    stage("Setup Workspace") {

        deleteDir()
        setupAnsibleEnvironment {}

    }

    stage("Sync Repositories") {
        def products = [
            'Red Hat Ansible Engine',
        ]

        runPlaybookInParallel {
            name = "sync"
            items = products
            item_name = 'product'
            playbook = 'playbooks/sync_products.yml'
        }
    }

    stage("Publish Content Views") {
        def content_views = [
            'Ansible',
        ]

        runPlaybookInParallel {
            name = "publish"
            items = content_views
            item_name = 'content_view'
            playbook = 'playbooks/publish_content_views.yml'
        }
    }
}
