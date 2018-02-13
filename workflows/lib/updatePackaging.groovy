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
                sh "TOOL_BELT_CONFIGS=${tool_belt_config} bundle exec ./bin/tool-belt setup-environment --version ${packaging_version} --gitlab-username ${env.USERNAME} --gitlab-password ${env.PASSWORD} --gitlab-clone-method https --repos satellite-packaging"
            }
        }

    }

    stage("Get package name") {

        dir("tool_belt") {
            sh "TOOL_BELT_CONFIGS=${tool_belt_config} bundle exec ./bin/tool-belt release package-name --version ${packaging_version} --project ${project} --output-file package_name --no-update-repos"
            package_name = readFile 'package_name'
        }

    }

    stage("Generate changelog entry") {

        dir("tool_belt") {
            withCredentials([string(credentialsId: 'gitlab-jenkins-user-api-token-string', variable: 'GITLAB_TOKEN')]) {
                sh "TOOL_BELT_CONFIGS=${tool_belt_config} bundle exec ./bin/tool-belt release changelog --version ${packaging_version} --project ${project} --gitlab-username jenkins --gitlab-token ${env.GITLAB_TOKEN} --update-to ${version} --output-file changelog"
            }
            changelog = readFile 'changelog'
        }

    }

    stage("Prepare changes") {

        dir("tool_belt/repos/satellite_${packaging_version}/satellite-packaging") {
            obal {
                action = 'update'
                packages = package_name
                extraVars = [
                    'downstream_version': version,
                    'downstream_changelog': changelog
                ]
            }
        }

    }

    stage ("Create MR") {
        def branch = "jenkins/update-${project}-${version}"
        def commit_msg = "Update ${project} to ${version}"

        dir("tool_belt/repos/satellite_${packaging_version}/satellite-packaging") {
            sh "git checkout -b ${branch}"
            sh "git commit -a -m '${commit_msg}'"
            sh "git push jenkins ${branch} -f"
        }

        dir("tool_belt") {
            withCredentials([string(credentialsId: 'gitlab-jenkins-user-api-token-string', variable: 'GITLAB_TOKEN')]) {
                sh "TOOL_BELT_CONFIGS=${tool_belt_config} bundle exec ./bin/tool-belt git merge-request --gitlab-username jenkins --gitlab-token ${env.GITLAB_TOKEN} --repo satellite-packaging --source-branch ${branch} --target-branch ${env.gitlabTargetBranch} --title '${commit_msg}'"
            }
        }

    }

}
