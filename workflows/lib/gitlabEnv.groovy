if (!env.getProperty('gitlabTargetBranch') && env.getProperty('targetBranch')) {
    env.setProperty('gitlabSourceBranch', env.getProperty('sourceBranch'))
    env.setProperty('gitlabSourceRepoName', env.getProperty('sourceRepoName'))
    env.setProperty('gitlabSourceNamespace', '')
    env.setProperty('gitlabTargetBranch', env.getProperty('targetBranch'))
}
