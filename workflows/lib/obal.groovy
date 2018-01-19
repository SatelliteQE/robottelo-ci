def obal(body) {

    def config = [:]
    body.resolveStrategy = Closure.DELEGATE_FIRST
    body.delegate = config
    body()

    def tags = config.tags ? "--tags ${config.tags}" : ""

    dir('obal') {
        git url: "https://github.com/evgeni/obal.git", branch: "master"
    }

    wrap([$class: 'AnsiColorBuildWrapper', colorMapName: "xterm"]) {
        sh "ANSIBLE_FORCE_COLOR=true PYTHONPATH=obal/ python -m obal.__init__ ${tags} ${config.action} ${config.packages}"
    }
}
