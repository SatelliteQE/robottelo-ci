import groovy.json.JsonSlurper

node('sat6-rhel7') {

    snapperStage("Setup Workspace") {

        deleteDir()
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


    snapperStage("Sync Satellite Repositories") {

        runPlaybookInParallel {
            name = "sync"
            items = satellite_repositories
            item_name = 'repository'
            extra_vars = ['product': 'Satellite 6.3 Composes']
            playbook = 'playbooks/sync_repositories.yml'
        }
    }

    snapperStage("Sync Capsule Repositories") {

        runPlaybookInParallel {
            name = "sync"
            items = capsule_repositories
            item_name = 'repository'
            extra_vars = ['product': 'Satellite Capsule 6.3 Composes']
            playbook = 'playbooks/sync_repositories.yml'
        }
    }

    snapperStage("Sync Tools Repositories") {

        runPlaybookInParallel {
            name = "sync"
            items = tools_repositories
            item_name = 'repository'
            extra_vars = ['product': 'Satellite Tools 6.3 Composes']
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

    snapperStage("Setup Packaging Workspace") {

        deleteDir()
        dir('tool_belt') {
            setup_toolbelt()
        }
    }

    snapperStage("Compare Packages") {

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

    snapperStage("Move to ON_DEV") {
        dir('tool_belt') {
            withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'bugzilla-credentials', passwordVariable: 'BZ_PASSWORD', usernameVariable: 'BZ_USERNAME']]) {

                sh "bundle exec ./tools.rb bugzilla move-to-on-dev --bz-username ${env.BZ_USERNAME} --bz-password ${env.BZ_PASSWORD} --version ${satellite_version} --packages package_report.yaml --commit"

            }
        }

    }
}

def runOnLibvirtHost(action) {
    sh "ssh jenkins@${env.LIBVIRT_HOST} \"${action}\""
}
