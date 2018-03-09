def version = env.version
def project = env.project
def changelog = ''
def package_name = ''

node ('sat6-rhel7') {

    stage("Setup Environment") {

        deleteDir()

        dir('tool_belt') {
            setup_toolbelt()
        }

    }

    stage("Clone packaging git") {

        dir("tool_belt") {
            withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'jenkins-gitlab', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME']]) {

                toolBelt(
                    command: 'bugzilla setup-environment',
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

    }

    stage("Get package name") {

        dir("tool_belt") {
            toolBelt(
                command: 'release package-name',
                config: tool_belt_config,
                options: [
                    "--version ${package_version}",
                    "--project ${project}",
                    "--output-file package_name",
                    "--no-update-repos"
                ]
            }
            package_name = readFile 'package_name'
        }

    }

    stage("Generate changelog entry") {

        dir("tool_belt") {
            withCredentials([string(credentialsId: 'gitlab-jenkins-user-api-token-string', variable: 'GITLAB_TOKEN')]) {

                toolBelt(
                    command: 'release changelog',
                    config: tool_belt_config,
                    options: [
                        "--version ${package_version}",
                        "--project ${project}",
                        "--gitlab-username jenkins",
                        "--gitlab-token ${env.GITLAB_TOKEN}",
                        "--update-to ${version}",
                        "--output-file changelog"
                    ]
                )

            }
            changelog = readFile 'changelog'
        }

    }

    stage("Prepare changes") {

        dir("tool_belt/repos/${tool_belt_repo_folder}/${packaging_repo}") {
            obal (
                action: 'update',
                packages: package_name,
                extraVars: [
                    'downstream_version': version,
                    'downstream_changelog': changelog
                )
            }
        }

    }

    stage ("Create MR") {
        def branch = "jenkins/update-${project}-${version}"
        def commit_msg = "Update ${project} to ${version}"

        dir("tool_belt/repos/${tool_belt_repo_folder}/${packaging_repo}") {
            sh "git checkout -b ${branch}"
            sh "git commit -a -m '${commit_msg}'"
            sh "git push jenkins ${branch} -f"
        }

        dir("tool_belt") {
            withCredentials([string(credentialsId: 'gitlab-jenkins-user-api-token-string', variable: 'GITLAB_TOKEN')]) {

                toolBelt(
                    command: 'git merge-request',
                    config: tool_belt_config,
                    options: [
                        "--version ${package_version}",
                        "--project ${project}",
                        "--gitlab-username jenkins",
                        "--gitlab-token ${env.GITLAB_TOKEN}",
                        "--repo '${packaging_repo_project}/${packaging_repo}",
                        "--source-branch ${branch}",
                        "--target-branch ${env.gitlabTargetBranch}",
                        "--title '${commit_msg}'"
                    ]
                )

            }
        }

    }

}
