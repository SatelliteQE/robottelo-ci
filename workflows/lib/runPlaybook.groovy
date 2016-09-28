def runPlaybookInParallel(body) {

    def config = [:]
    body.resolveStrategy = Closure.DELEGATE_FIRST
    body.delegate = config
    body()

    def branches = [:]
    def name = config.name ?: "split"

    for (int i = 0; i < config.items.size(); i++) {
        def index = i // fresh variable per iteration; i will be mutated
        branches["${name}-${config.items.get(i)}"] = {

            runPlaybook {
                playbook = config.playbook
                extraVars = [(config.item_name): config.items.get(index)]
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

            if (config.extraVars) {
                extraVars = defaultVars + config.extraVars
            } else {
                extraVars = defaultVars
            }

            dir('ansible') {
                ansiblePlaybook(
                    playbook: config.playbook,
                    inventory: 'sat-infra/inventory',
                    colorized: true,
                    extraVars: extraVars
                )
            }

        }
    }
}
