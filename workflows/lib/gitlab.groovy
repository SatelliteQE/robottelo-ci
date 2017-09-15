def gitlab_clone_and_merge(repo_name) {
    try {
        updateGitlabCommitStatus state: 'running'
        if (env.gitlabSourceRepoName) {
            checkout changelog: true, poll: true, scm: [
                $class: 'GitSCM',
                branches: [[name: "pr/${env.gitlabSourceBranch}"]],
                doGenerateSubmoduleConfigurations: false,
                extensions: [[$class: 'PreBuildMerge', options: [fastForwardMode: 'FF', mergeRemote: 'origin', mergeStrategy: 'default', mergeTarget: "${env.gitlabTargetBranch}"]]],
                submoduleCfg: [],
                userRemoteConfigs: [[name: 'origin', url: "https://$GIT_HOSTNAME/$GIT_ORGANIZATION/${repo_name}.git"], [name: 'pr', url: "https://$GIT_HOSTNAME/${env.gitlabSourceNamespace}/${env.gitlabSourceRepoName}.git"]]
              ]
        } else {
            git url: "https://$GIT_HOSTNAME/$GIT_ORGANIZATION/${repo_name}.git", branch: gitlabTargetBranch
        }
    } catch (e) {
        updateGitlabCommitStatus state: 'failed'
        currentBuild.result = "FAILED"
        throw e
    }
}
