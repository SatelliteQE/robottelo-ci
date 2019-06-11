def version = env.version
def changelog = ''
def package_name = ''

node ('sat6-build') {

    stage("Setup Environment") {

        deleteDir()

    }

    stage("Clone packaging git") {

        withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'jenkins-gitlab', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME']]) {

            toolBelt(
                command: 'setup-environment',
                config: tool_belt_config,
                options: [
                    "--version ${package_version}",
                    "--gitlab-username ${env.USERNAME}",
                    "--gitlab-password ${env.PASSWORD}",
                    "--gitlab-clone-method https",
                    "--repos ${packaging_repo}"
                ]
            )
        }

    }

    stage("Get package name") {

        toolBelt(
            command: 'release package-name',
            config: tool_belt_config,
            options: [
                "--version ${package_version}",
                "--project ${project}",
                "--output-file package_name",
                "--no-update-repos"
            ]
        )
        package_name = readFile 'tool_belt/package_name'

    }


    stage("Prepare changes") {

        dir("tool_belt/repos/${tool_belt_repo_folder}/${packaging_repo}") {
            setup_obal()

            obal(
                action: 'bump-release',
                packages: package_name
            )
        }

    }

    stage ("Create MR") {
        createMergeRequest(project, version)
    }

}
