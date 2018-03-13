node('sat6-rhel7') {

    stage("Setup Workspace") {

        deleteDir()
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
                "compose_version": "satellite-${satellite_main_version}",
                "compose_label": "Satellite-${satellite_main_version}",
                "compose_name": "satellite-${satellite_main_version}"
            ]
        }

        runPlaybookInParallel {
            name = "compose-tools-rhel"
            items = tools_compose_versions
            item_name = 'rhel_version'
            playbook = 'playbooks/build_compose.yml'
            extraVars = [
                'compose_git_repo': compose_git_repo,
                "compose_version": "satellite-${satellite_main_version}",
                "compose_label": "SatTools-${satellite_main_version}",
                "compose_name": "satellite-tools-${satellite_main_version}"
            ]
        }
    }

    stage("Test Installation") {

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


    stage("Sync Satellite Repositories") {

        runPlaybookInParallel {
            name = "sync"
            items = satellite_repositories
            item_name = 'repository'
            extraVars = ["product": "Satellite ${satellite_main_version} Composes"]
            playbook = 'playbooks/sync_repositories.yml'
        }
    }

    stage("Sync Capsule Repositories") {

        runPlaybookInParallel {
            name = "sync"
            items = capsule_repositories
            item_name = 'repository'
            extraVars = ["product": "Satellite Capsule ${satellite_main_version} Composes"]
            playbook = 'playbooks/sync_repositories.yml'
        }
    }

    stage("Sync Tools Repositories") {

        runPlaybookInParallel {
            name = "sync"
            items = tools_repositories
            item_name = 'repository'
            extraVars = ["product": "Satellite Tools ${satellite_main_version} Composes"]
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

node('rhel') {

    stage("Setup Packaging Workspace") {

        deleteDir()
        dir('tool_belt') {
            setup_toolbelt()
        }
    }

    stage("Compare Packages") {

        compareContentViews {
          organization = 'Sat6-CI'
          content_view = "Satellite ${satellite_main_version} with RHEL7 Server"
          from_lifecycle_environment = 'Library'
          to_lifecycle_environment = 'QA'
        }

        compareContentViews {
          organization = 'Sat6-CI'
          content_view = "Capsule ${satellite_main_version} with RHEL7 Server"
          from_lifecycle_environment = 'Library'
          to_lifecycle_environment = 'QA'
        }

        compareContentViews {
          organization = 'Sat6-CI'
          content_view = "Tools ${satellite_main_version} with RHEL7 Server"
          from_lifecycle_environment = 'Library'
          to_lifecycle_environment = 'QA'
        }

        compareContentViews {
          organization = 'Sat6-CI'
          content_view = "Tools ${satellite_main_version} with RHEL6 Server"
          from_lifecycle_environment = 'Library'
          to_lifecycle_environment = 'QA'
        }

        compareContentViews {
          organization = 'Sat6-CI'
          content_view = "Tools ${satellite_main_version} with RHEL5 Server"
          from_lifecycle_environment = 'Library'
          to_lifecycle_environment = 'QA'
        }
    }

    stage("Move to ON_DEV") {
        dir('tool_belt') {
            withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'bugzilla-credentials', passwordVariable: 'BZ_PASSWORD', usernameVariable: 'BZ_USERNAME']]) {

                toolBelt(
                    command: 'bugzilla move-to-on-dev',
                    options: [
                        "--bz-username ${env.BZ_USERNAME}",
                        "--bz-password ${env.BZ_PASSWORD}",
                        "--version ${satellite_version}",
                        "--packages package_report.yaml",
                        " --commit"
                    ]
                )

            }
        }

    }
}

def runOnLibvirtHost(action) {
    sh "ssh jenkins@${env.LIBVIRT_HOST} \"${action}\""
}
