def setupAnsibleEnvironment(body) {

    def config = [:]
    body = body ?: [:]

    body.resolveStrategy = Closure.DELEGATE_FIRST
    body.delegate = config
    body()

    def git_remote = config.git_remote ?: 'SatelliteQE'
    def git_repo = config.git_repo ?: 'robottelo-ci'
    def git_branch = config.git_branch ?: 'master'

    git url: "https://github.com/${git_remote}/${git_repo}", branch: git_branch

}

def runPlaybook(body) {

    def config = [:]
    body.resolveStrategy = Closure.DELEGATE_FIRST
    body.delegate = config
    body()


    wrap([$class: 'AnsiColorBuildWrapper', colorMapName: "xterm"]) {

        def inventoryContent = config.inventoryContent ?: null
        def ansibledir = config.ansibledir ?: null

        dir(ansibledir) {
            ansiblePlaybook(
                playbook: config.playbook,
                inventoryContent: inventoryContent,
                colorized: true,
                extraVars: config.extraVars
            )
        }
    }
}
