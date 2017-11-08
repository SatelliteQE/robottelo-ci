def setup_toolbelt() {
    git url: "https://${env.GIT_HOSTNAME}/${env.GIT_ORGANIZATION}/tool_belt.git", branch: 'master'
    sh 'bundle install --without=development'
}
