if (!env.getProperty('gitlabTargetBranch') && env.getProperty('targetBranch')) {
    env.setProperty('gitlabSourceBranch', env.getProperty('sourceBranch'))
    env.setProperty('gitlabSourceRepoName', env.getProperty('sourceRepoName'))
    env.setProperty('gitlabSourceNamespace', '')
    env.setProperty('gitlabTargetBranch', env.getProperty('targetBranch'))
}
if (!env.getProperty('gitlabTargetBranch') && env.getProperty('releaseBranch')) {
    env.setProperty('gitlabTargetBranch', env.getProperty('releaseBranch'))
}
if (!env.getProperty('gitlabSourceRepoHttpUrl')) {
    env.setProperty('gitlabSourceRepoHttpUrl', "https://$GIT_HOSTNAME/${env.gitlabSourceNamespace}/${env.gitlabSourceRepoName}.git")
}
