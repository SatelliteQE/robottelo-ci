node('sat6-build') {

    stage("Setup Workspace") {

        deleteDir()
        setupAnsibleEnvironment {}

    }

    stage("Clean Content Views") {

        runDownstreamPlaybook {
            playbook = 'playbooks/content_view_version_cleanup.yml'
            extraVars = [
                'organization': 'Sat6-CI',
            ]
        }

    }
}
