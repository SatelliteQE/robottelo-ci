def setupAnsibleEnvironment(body) {

    def config = [:]
    body = body ?: [:]

    body.resolveStrategy = Closure.DELEGATE_FIRST
    body.delegate = config
    body()

    def robottelo_remote = config.robottelo_remote ?: 'SatelliteQE'
    def robottelo_branch = config.robottelo_branch ?: 'master'

    git url: "https://github.com/${robottelo_remote}/robottelo-ci", branch: robottelo_branch

    dir('ansible') {
        dir('sat-infra') {
            git url: "https://${env.GIT_HOSTNAME}/satellite6/sat-infra.git"
        }

        dir('foreman-ansible-modules') {
            git url: "https://github.com/theforeman/foreman-ansible-modules.git"
        }
    }

}

def runPlaybookInParallel(body) {

    def config = [:]
    body.resolveStrategy = Closure.DELEGATE_FIRST
    body.delegate = config
    body()

    def branches = [:]
    def name = config.name ?: "split"
    def extra_vars = config.extraVars ?: [:]

    for (int i = 0; i < config.items.size(); i++) {
        def index = i // fresh variable per iteration; i will be mutated
        branches["${name}-${config.items.get(i)}"] = {

            runPlaybook {
                playbook = config.playbook
                extraVars = extra_vars + [(config.item_name): config.items.get(index)]
            }

        }
    }

    parallel branches

}

def runPlaybook(body) {

    def config = [:]
    body.resolveStrategy = Closure.DELEGATE_FIRST
    body.delegate = config
    body()

    withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'artefact-satellite-credentials', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME']]) {
        wrap([$class: 'AnsiColorBuildWrapper', colorMapName: "xterm"]) {

            def extraVars = []
            def defaultVars = [
                server: env.SATELLITE_SERVER,
                username: env.USERNAME,
                password: env.PASSWORD
            ]
            def inventory = config.inventory ?: 'sat-infra/inventory'
            def tags = config.tags ?: null
            def limit = config.limit ?: null
            def ansibledir = config.ansibledir ?: 'ansible'

            if (config.extraVars) {
                extraVars = defaultVars + config.extraVars
            } else {
                extraVars = defaultVars
            }

            dir(ansibledir) {
                ansiblePlaybook(
                    playbook: config.playbook,
                    inventory: inventory,
                    colorized: true,
                    limit: limit,
                    tags: tags,
                    extraVars: extraVars
                )
            }

        }
    }
}
