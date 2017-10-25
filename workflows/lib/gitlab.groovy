def gitlab_clone_and_merge(repo_name, pipeline_name='jenkins') {
    def merge = true
    if (pipeline_name == 'release') {
        merge = false;
    }
    try {
        updateGitlabCommitStatus state: 'running', name: pipeline_name
        if (merge && env.gitlabSourceRepoName) {
            checkout changelog: true, poll: true, scm: [
                $class: 'GitSCM',
                branches: [[name: "pr/${env.gitlabSourceBranch}"]],
                doGenerateSubmoduleConfigurations: false,
                extensions: [[$class: 'PreBuildMerge', options: [fastForwardMode: 'FF', mergeRemote: 'origin', mergeStrategy: 'default', mergeTarget: "${env.gitlabTargetBranch}"]]],
                submoduleCfg: [],
                userRemoteConfigs: [[name: 'origin', url: "https://$GIT_HOSTNAME/$GIT_ORGANIZATION/${repo_name}.git"], [name: 'pr', url: "https://$GIT_HOSTNAME/${env.gitlabSourceNamespace}/${env.gitlabSourceRepoName}.git"]]
              ]
        } else {
            git url: "https://$GIT_HOSTNAME/$GIT_ORGANIZATION/${repo_name}.git", branch: "${env.gitlabTargetBranch}"
        }
    } catch (e) {
        updateGitlabCommitStatus state: 'failed', name: pipeline_name
        currentBuild.result = "FAILED"
        throw e
    }
}
