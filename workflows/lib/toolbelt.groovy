def setup_toolbelt() {
    git url: "https://${env.GIT_HOSTNAME}/${env.GIT_ORGANIZATION}/tool_belt.git", branch: 'master'
    sh 'bundle install --without=development'
}

def toolBelt(body) {

    def config = [:]
    body = body ?: [:]

    body.resolveStrategy = Closure.DELEGATE_FIRST
    body.delegate = config
    body()

    tool_belt_config = config.config ? "TOOL_BELT_CONFIGS=${config.config}" : ""

    sh "${tool_belt_config} bundle exec ruby ./bin/tool-belt ${config.command} ${config.options.join(' ')}"
}
