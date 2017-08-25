import groovy.json.JsonSlurper

node('sat6-rhel7') {

    snapperStage("Setup Workspace") {

        setupAnsibleEnvironment {}

    }

    snapperStage("Generate Composes") {

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
                'compose_version': 'satellite-6.3',
                'compose_label': 'Satellite-6.3',
                'compose_name': 'satellite-6.3'
            ]
        }

        runPlaybookInParallel {
            name = "compose-tools-rhel"
            items = tools_compose_versions
            item_name = 'rhel_version'
            playbook = 'playbooks/build_compose.yml'
            extraVars = [
                'compose_git_repo': compose_git_repo,
                'compose_version': 'satellite-6.3',
                'compose_label': 'SatTools-6.3',
                'compose_name': 'satellite-tools-6.3'
            ]
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

node('rhel') {

    snapperStage("Compare Packages") {

      // Remove old package report
        sh 'rm -f package_report.yaml'

        compareContentViews {
          organization = 'Sat6-CI'
          content_view = 'Satellite 6.3 RHEL7'
          from_lifecycle_environment = 'Library'
          to_lifecycle_environment = 'QA'
        }

        compareContentViews {
          organization = 'Sat6-CI'
          content_view = 'Capsule 6.3 RHEL7'
          from_lifecycle_environment = 'Library'
          to_lifecycle_environment = 'QA'
        }

        compareContentViews {
          organization = 'Sat6-CI'
          content_view = 'Tools 6.3 RHEL7'
          from_lifecycle_environment = 'Library'
          to_lifecycle_environment = 'QA'
        }

        compareContentViews {
          organization = 'Sat6-CI'
          content_view = 'Tools 6.3 RHEL6'
          from_lifecycle_environment = 'Library'
          to_lifecycle_environment = 'QA'
        }

        compareContentViews {
          organization = 'Sat6-CI'
          content_view = 'Tools 6.3 RHEL5'
          from_lifecycle_environment = 'Library'
          to_lifecycle_environment = 'QA'
        }
    }
}

def runOnLibvirtHost(action) {
    sh "ssh jenkins@${env.LIBVIRT_HOST} \"${action}\""
}
