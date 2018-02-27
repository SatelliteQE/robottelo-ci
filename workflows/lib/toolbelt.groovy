def setup_toolbelt() {
    git url: "https://${env.GIT_HOSTNAME}/${env.GIT_ORGANIZATION}/tool_belt.git", branch: 'master'
    sh 'bundle install --without=development'
}

def toolBelt(args) {
    tool_belt_config = args.config ? "TOOL_BELT_CONFIGS=${args.config}" : ""

    sh "${tool_belt_config} bundle exec ruby ./bin/tool-belt ${args.command} ${args.options.join(' ')}"
}
