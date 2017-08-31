def version = '6.2.0'
def milestone = '6.2.12'

node('rhel') {

    stage("Setup ToolBelt") {
        git url: "https://${env.GIT_HOSTNAME}/Satellite6/tool_belt.git", branch: 'master'
        sh 'bundle install --without=development'
        sh "bundle exec ruby ./tools.rb setup-environment --bugzilla --gitlab-username jenkins --version ${version}"
    }

    stage("Identify Cherry Picks") {

        withCredentials([
            [$class: 'UsernamePasswordMultiBinding', credentialsId: 'bugzilla-credentials', passwordVariable: 'BZ_PASSWORD', usernameVariable: 'BZ_USERNAME'],
            [$class: 'UsernamePasswordMultiBinding', credentialsId: 'octokit_token', passwordVariable: 'OCTOKIT_ACCESS_TOKEN', usernameVariable: 'OCTOKIT_TOKEN']]) {

                sh "bundle exec ruby ./tools.rb bugzilla cherry-pick --username ${env.BZ_USERNAME} --password ${env.BZ_PASSWORD} --version ${version} --milestone ${milestone} --no-update-repos"
                archive "releases/${version}/bugzillas"
          }
    }

}
