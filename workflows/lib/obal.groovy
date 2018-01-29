// source: https://issues.jenkins-ci.org/browse/JENKINS-44231
// Given arbitrary string returns a strongly escaped shell string literal.
// I.e. it will be in single quotes which turns off interpolation of $(...), etc.
// E.g.: 1'2\3\'4 5"6 (groovy string) -> '1'\''2\3\'\''4 5"6' (groovy string which can be safely pasted into shell command).
def shellString(s) {
    // Replace ' with '\'' (https://unix.stackexchange.com/a/187654/260156). Then enclose with '...'.
    // 1) Why not replace \ with \\? Because '...' does not treat backslashes in a special way.
    // 2) And why not use ANSI-C quoting? I.e. we could replace ' with \'
    // and enclose using $'...' (https://stackoverflow.com/a/8254156/4839573).
    // Because ANSI-C quoting is not yet supported by Dash (default shell in Ubuntu & Debian) (https://unix.stackexchange.com/a/371873).
    '\'' + s.replace('\'', '\'\\\'\'') + '\''
}

def obal(body) {

    def config = [:]
    body.resolveStrategy = Closure.DELEGATE_FIRST
    body.delegate = config
    body()

    def tags = config.tags ? "--tags ${config.tags}" : ""
    def extra_vars = config.extraVars ?: [:]
    def extra_vars_args = []
    extra_vars.each { key, val ->
       vararg = shellString($/${key}="${val}"/$)
       extra_vars_args += $/-e ${vararg}/$
    }

    dir('obal') {
        git url: "https://github.com/evgeni/obal.git", branch: "master"
    }

    wrap([$class: 'AnsiColorBuildWrapper', colorMapName: "xterm"]) {
        sh "ANSIBLE_FORCE_COLOR=true PYTHONPATH=obal/ python -m obal.__init__ ${tags} ${extra_vars_args.join(' ')} ${config.action} ${config.packages}"
    }
}
