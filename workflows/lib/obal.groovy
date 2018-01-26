def obal(body) {

    def config = [:]
    body.resolveStrategy = Closure.DELEGATE_FIRST
    body.delegate = config
    body()

    def tags = config.tags ? "--tags ${config.tags}" : ""
    def extra_vars = config.extraVars ?: [:]
    def extra_vars_args = []
    extra_vars.each { key, val ->
       extra_vars_args += $/-e '${key}=${val}'/$
    }

    dir('obal') {
        git url: "https://github.com/evgeni/obal.git", branch: "master"
    }

    wrap([$class: 'AnsiColorBuildWrapper', colorMapName: "xterm"]) {
        sh "ANSIBLE_FORCE_COLOR=true PYTHONPATH=obal/ python -m obal.__init__ ${tags} ${extra_vars_args.join(' ')} ${config.action} ${config.packages}"
    }
}
