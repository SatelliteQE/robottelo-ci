def version = env.version
def project = env.project
def changelog = ''
def package_name = ''
def satellite_version = env.gitlabTargetBranch.minus('SATELLITE-')

node ('sat6-rhel7') {

    snapperStage("Setup Environment") {

        deleteDir()

        dir('tool_belt') {
            setup_toolbelt()
        }

    }

    snapperStage("Clone packaging git") {

        dir("tool_belt") {
            withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'jenkins-gitlab', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME']]) {
                sh "bundle exec ./tools.rb setup-environment --version ${satellite_version} --gitlab-username ${env.USERNAME} --gitlab-password ${env.PASSWORD} --gitlab-clone-method https --repos satellite-packaging"
            }
        }

    }

    snapperStage("Get package name") {

        dir("tool_belt") {
            sh "bundle exec ./tools.rb release package-name --version ${satellite_version} --project ${project} --output-file package_name --no-update-repos"
            package_name = readFile 'package_name'
        }

    }

    snapperStage("Generate changelog entry") {

        dir("tool_belt") {
            withCredentials([string(credentialsId: 'gitlab-jenkins-user-api-token-string', variable: 'GITLAB_TOKEN')]) {
                sh "bundle exec ./tools.rb release changelog --version ${satellite_version} --project ${project} --gitlab-username jenkins --gitlab-token ${env.GITLAB_TOKEN} --update-to ${version} --output-file changelog"
            }
            changelog = readFile 'changelog'
        }

    }

    snapperStage("Prepare changes") {

        dir("tool_belt/repos/satellite_${satellite_version}/satellite-packaging") {
            runPlaybook {
                ansibledir = '.'
                inventory = 'package_manifest.yaml'
                playbook = 'update_package.yml'
                limit = package_name
                extraVars = [
                    'downstream_version': version,
                    'downstream_changelog': changelog
                ]
            }
        }

    }

    snapperStage ("Create MR") {
        def branch = "jenkins/update-${project}-${version}"
        def commit_msg = "Update ${project} to ${version}"

        dir("tool_belt/repos/satellite_${satellite_version}/satellite-packaging") {
            sh "git checkout -b ${branch}"
            sh "git commit -a -m '${commit_msg}'"
            sh "git push jenkins ${branch} -f"
        }

        dir("tool_belt") {
            withCredentials([string(credentialsId: 'gitlab-jenkins-user-api-token-string', variable: 'GITLAB_TOKEN')]) {
                sh "bundle exec ./tools.rb git merge-request --gitlab-username jenkins --gitlab-token ${env.GITLAB_TOKEN} --repo satellite-packaging --source-branch ${branch} --target-branch ${env.gitlabTargetBranch} --title '${commit_msg}'"
            }
        }

    }

}
