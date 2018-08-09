def setup_toolbelt() {
    dir ('tool_belt') {
        checkout([
            $class : 'GitSCM',
            branches : [[name: 'master']],
            extensions: [[$class: 'CleanCheckout']],
            userRemoteConfigs: [
                [url: "https://${env.GIT_HOSTNAME}/${env.GIT_ORGANIZATION}/tool_belt.git"]
            ]
        ])
        sh 'bundle install --without=development'
    }
}

def toolBelt(args) {
    if (!fileExists('tool_belt')) {
        setup_toolbelt()
    }

    dir ('tool_belt') {
        tool_belt_config = args.config ? "TOOL_BELT_CONFIGS=${args.config}" : ""

        sh "${tool_belt_config} bundle exec ruby ./bin/tool-belt ${args.command} ${args.options.join(' ')}"
    }
}
