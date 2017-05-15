node('rhel') {
  stage "Identify Cherry Picks"

  withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'bugzilla-credentials', passwordVariable: 'BZ_PASSWORD', usernameVariable: 'BZ_USERNAME']]) {
    git url: "https://${env.GIT_HOSTNAME}/Satellite6/tool_belt.git", branch: 'master'
    sh 'bundle install'
    sh "./tools.rb bugzilla cherry-pick --username ${env.BZ_USERNAME} --password ${env.BZ_PASSWORD} --version 6.2.0 --milestone 6.2.10"
    archive "releases/6.2.0/bugzillas"
  }
}
