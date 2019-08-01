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
            checkout([
              $class: 'GitSCM',
              branches: [[name: 'master' ]],
              userRemoteConfigs: [[url: "https://github.com/theforeman/foreman-ansible-modules.git"]],
            ])
        }
    }

}

def runPlaybookSequentially(body) {

    def config = [:]
    body.resolveStrategy = Closure.DELEGATE_FIRST
    body.delegate = config
    body()

    def extra_vars = config.extraVars ?: [:]

    for (int i = 0; i < config.items.size(); i++) {

        runDownstreamPlaybook {
            playbook = config.playbook
            extraVars = extra_vars + [(config.item_name): config.items.get(i)]
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

            runDownstreamPlaybook {
                playbook = config.playbook
                extraVars = extra_vars + [(config.item_name): config.items.get(index)]
            }

        }
    }

    parallel branches

}

def runDownstreamPlaybook(body) {

    def config = [:]
    body.resolveStrategy = Closure.DELEGATE_FIRST
    body.delegate = config
    body()

    withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'artefact-satellite-credentials', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME']]) {
        wrap([$class: 'AnsiColorBuildWrapper', colorMapName: "xterm"]) {

            def extraVars = []
            def sensitiveVars = [
                server: env.SATELLITE_SERVER,
                username: env.USERNAME,
                password: env.PASSWORD
            ]
            def inventory = config.inventory ?: 'sat-infra/inventory'
            def ansibledir = config.ansibledir ?: 'ansible'

            dir(ansibledir) {
                runPlaybook(
                    playbook: config.playbook,
                    inventory: inventory,
                    extraVars: config.extraVars,
                    sensitiveExtraVars: sensitiveVars
                )
            }

        }
    }
}
