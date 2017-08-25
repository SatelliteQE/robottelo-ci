node('sat6-rhel7') {

    snapperStage("Setup Workspace") {
        setupAnsibleEnvironment {}
    }

    snapperStage("Generate Composes") {

        def git_hostname = env.GIT_HOSTNAME

        runPlaybook {
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

    snapperStage("Test Installation") {

        runOnLibvirtHost "cd sat-deploy && git -c http.sslVerify=false fetch origin && git reset origin/master --hard"
        runOnLibvirtHost "cd sat-deploy/forklift && git -c http.sslVerify=false fetch origin && git reset origin/master --hard"

        def branches = [:]

        wrap([$class: 'AnsiColorBuildWrapper', colorMapName: "xterm"]) {
            for (int i = 0; i < os_versions.size(); i++) {
                def index = i // fresh variable per iteration; i will be mutated
                def item = os_versions.get(index)

                branches["install-rhel-${item}"] = {
                    try {
                        runOnLibvirtHost "cd sat-deploy && ansible-playbook pipelines/compose_test_${satellite_short_version}_rhel${item}.yml -e forklift_state=up"
                    } finally {
                        runOnLibvirtHost "cd sat-deploy && ansible-playbook pipelines/compose_test_${satellite_short_version}_rhel${item}.yml -e forklift_state=destroy"
                    }
                }
            }
        }

        parallel branches
    }

    snapperStage("Sync Repositories") {

        runPlaybookInParallel {
            name = "sync"
            items = products
            item_name = 'product'
            playbook = 'playbooks/sync_repositories.yml'
        }

    }

    snapperStage("Publish Content Views") {

        runPlaybookInParallel {
            name = "publish"
            items = content_views
            item_name = 'content_view'
            playbook = 'playbooks/publish_content_views.yml'
        }
    }
}

def runOnLibvirtHost(action) {
    sh "ssh jenkins@${env.LIBVIRT_HOST} \"${action}\""
}
