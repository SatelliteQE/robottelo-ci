def createMergeRequest(project, version) {
    def branch = "jenkins/update-${project}-${version}"
    def commit_msg = "Update ${project} to ${version}"

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
                "--repo '${packaging_repo_project}/${packaging_repo}'",
                "--source-branch ${branch}",
                "--target-branch ${env.gitlabTargetBranch}",
                "--title '${commit_msg}'"
            ]
        )

    }

}
