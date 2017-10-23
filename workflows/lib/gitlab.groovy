def gitlab_clone_and_merge(repo_name, pipeline_name='jenkins') {
    def merge = (pipeline_name != 'release')
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
            gitlab_clone(repo_name)
        }
    } catch (e) {
        updateGitlabCommitStatus state: 'failed', name: pipeline_name
        currentBuild.result = "FAILED"
        throw e
    }
}

def gitlab_clone(repo_name) {
    git url: "https://$GIT_HOSTNAME/$GIT_ORGANIZATION/${repo_name}.git", branch: "${env.gitlabTargetBranch}"
}

def find_merge_commit(commit, branch) {
    // this beauty is taken verbatim from https://stackoverflow.com/a/30998048
    merge_commit = sh(returnStdout: true, script: "(git rev-list ${commit}..${branch} --ancestry-path | cat -n; git rev-list ${commit}..${branch} --first-parent | cat -n) | sort -k2 -s | uniq -f1 -d | sort -n | tail -1 | cut -f2").trim()
    return merge_commit
}
