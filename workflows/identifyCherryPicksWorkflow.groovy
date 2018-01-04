def version = '6.2.0'
def milestone = '6.2.14'

node('rhel') {

    stage("Setup ToolBelt") {
        setup_toolbelt()
        sh "bundle exec ruby ./tools.rb setup-environment --gitlab-username jenkins --version ${version}"
    }

    stage("Identify Cherry Picks") {

        withCredentials([
            [$class: 'UsernamePasswordMultiBinding', credentialsId: 'bugzilla-credentials', passwordVariable: 'BZ_PASSWORD', usernameVariable: 'BZ_USERNAME'],
            [$class: 'UsernamePasswordMultiBinding', credentialsId: 'octokit_token', passwordVariable: 'OCTOKIT_ACCESS_TOKEN', usernameVariable: 'OCTOKIT_TOKEN']]) {

                sh "bundle exec ruby ./tools.rb cherry-picks report --bz-username ${env.BZ_USERNAME} --bz-password ${env.BZ_PASSWORD} --version ${version} --milestone ${milestone} --no-update-repos"
                archive "releases/${version}/bugzillas"
          }
    }

}
