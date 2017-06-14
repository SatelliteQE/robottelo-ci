node('sat6-rhel7') {

    stage "Setup Workspace" {

        git url: 'https://github.com/SatelliteQE/robottelo-ci'

        dir('ansible') {
            dir('sat-infra') {
                git url: "https://${env.GIT_HOSTNAME}/satellite6/sat-infra.git"
            }

            dir('satellite-build') {
                git url: "https://${env.GIT_HOSTNAME}/satellite6/satellite-build.git"
            }
        }

    }

    stage "Generate Composes" {

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

    stage "Test Installation" {

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


    stage "Sync Repositories" {

        runPlaybookInParallel {
            name = "sync"
            items = products
            item_name = 'product'
            playbook = 'playbooks/sync_repositories.yml'
        }

    }

    stage "Publish Content Views" {

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
