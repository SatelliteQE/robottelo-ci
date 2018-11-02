node('sat6-build') {

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
                "compose_name": "satellite-${satellite_main_version}",
                'compose_tag': 'candidate'
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
                "compose_name": "satellite-tools-${satellite_main_version}",
                'compose_tag': 'candidate'
            ]
        }
    }

    stage("Test Installation") {

        test_forklift(
            os_versions: os_versions,
            satellite_version: satellite_short_version
        )

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

node('sat6-build') {

    stage("Setup Packaging Workspace") {

        deleteDir()

    }

    stage("Compare Packages") {

        composite_content_views.each { cv ->
          compareContentViews(
            organization: 'Sat6-CI',
            content_view: cv,
            from_lifecycle_environment: 'Library',
            to_lifecycle_environment: 'QA'
          )
        }

    }

    stage("Move to ON_DEV") {
        withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'bugzilla-credentials', passwordVariable: 'BZ_PASSWORD', usernameVariable: 'BZ_USERNAME']]) {

            toolBelt(
                command: 'bugzilla move-to-on-dev',
                options: [
                    "--bz-username ${env.BZ_USERNAME}",
                    "--bz-password ${env.BZ_PASSWORD}",
                    "--version ${satellite_version}",
                    "--packages package_report.yaml",
                    "--commit"
                ]
            )

        }
    }
}
