package_version = env.branch.minus('SATELLITE-')
package_version_lower = package_version.toLowerCase()
package_name = env.package_name
project_repo = env.gitlab_repo.split('/')
packaging_project = project_repo[0]
packaging_repo = project_repo[1]
tool_belt_repo_folder = "satellite_${package_version_lower}"
tool_belt_config = './configs/satellite/'

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
                    "--version ${package_version_lower}",
                    "--gitlab-username ${env.USERNAME}",
                    "--gitlab-password ${env.PASSWORD}",
                    "--gitlab-clone-method https",
                    "--repos ${packaging_repo}"
                ]
            )
        }

    }


    stage("obal update") {

        dir("tool_belt/repos/${tool_belt_repo_folder}/${packaging_repo}") {
            setup_obal()

            obal(
                action: 'update',
                packages: package_name,
                extraVars: [
                    'commit': true,
                ]
            )
        }

    }

    stage ("Create MR") {
        createMergeRequest(package_name, env.branch)
    }

}

def createMergeRequest(project, target_branch) {
    def branch = "jenkins/update-${project}"
    def commit_msg = "Update ${project} from upstream"

    dir("tool_belt/repos/${tool_belt_repo_folder}/${packaging_repo}") {
        sh "git checkout -b ${branch}"
        sh "git push jenkins ${branch} -f"
    }

    withCredentials([string(credentialsId: 'gitlab-jenkins-user-api-token-string', variable: 'GITLAB_TOKEN')]) {

        toolBelt(
            command: 'git merge-request',
            config: tool_belt_config,
            options: [
                "--gitlab-username jenkins",
                "--gitlab-token ${env.GITLAB_TOKEN}",
                "--repo '${packaging_project}/${packaging_repo}'",
                "--source-branch ${branch}",
                "--target-branch ${target_branch}",
                "--title '${commit_msg}'"
            ]
        )

    }

}