def gitlab_clone_and_merge(repo_name, pipeline_name='jenkins') {
    repo_name = sanitize_repo_name(repo_name)
    def merge = (pipeline_name != 'release')
    try {
        updateGitlabCommitStatus state: 'running', name: pipeline_name
        if (merge && env.gitlabSourceRepoName) {
            checkout changelog: true, poll: true, scm: [
                $class: 'GitSCM',
                branches: [[name: "pr/${env.gitlabSourceBranch}"]],
                doGenerateSubmoduleConfigurations: false,
                extensions: [
                    [$class: 'PreBuildMerge', options: [fastForwardMode: 'FF', mergeRemote: 'origin', mergeStrategy: 'DEFAULT', mergeTarget: "${env.gitlabTargetBranch}"]],
                    [$class: 'CloneOption', depth: 0, noTags: false, reference: '', shallow: false, timeout: 20]
                ],
                submoduleCfg: [],
                userRemoteConfigs: [[name: 'origin', url: "https://$GIT_HOSTNAME/${repo_name}.git"], [name: 'pr', url: "https://$GIT_HOSTNAME/${env.gitlabSourceNamespace}/${env.gitlabSourceRepoName}.git"]]
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
    repo_name = sanitize_repo_name(repo_name)
    checkout([
        $class: 'GitSCM',
        branches: [[name: "*/${env.gitlabTargetBranch}"]],
        userRemoteConfigs: [[url: "https://$GIT_HOSTNAME/${repo_name}.git"]],
        extensions: [[$class: 'CloneOption', depth: 0, noTags: false, reference: '', shallow: false, timeout: 20]],
    ])
}

def find_merge_commit(commit, branch) {
    // this beauty is taken verbatim from https://stackoverflow.com/a/30998048
    merge_commit = sh(returnStdout: true, script: "(git rev-list ${commit}..${branch} --ancestry-path | cat -n; git rev-list ${commit}..${branch} --first-parent | cat -n) | sort -k2 -s | uniq -f1 -d | sort -n | tail -1 | cut -f2").trim()
    return merge_commit
}

def sanitize_repo_name(repo_name) {
    if ( !repo_name.contains('/') ) {
        repo_name = "$GIT_ORGANIZATION/${repo_name}"
    }
    return repo_name
}
