node('rhel') {

    stage("Setup ToolBelt") {
        git url: "https://${env.GIT_HOSTNAME}/Satellite6/tool_belt.git", branch: 'master'
        sh 'bundle install'
        sh './tools.rb setup-environment --bugzilla --gitlab-username jenkins --version 6.2.0'
    }

    stage("Identify Cherry Picks") {

        withCredentials([
            [$class: 'UsernamePasswordMultiBinding', credentialsId: 'bugzilla-credentials', passwordVariable: 'BZ_PASSWORD', usernameVariable: 'BZ_USERNAME'],
            [$class: 'UsernamePasswordMultiBinding', credentialsId: 'octokit_token', passwordVariable: 'OCTOKIT_ACCESS_TOKEN', usernameVariable: 'OCTOKIT_TOKEN']]) {

                sh "./tools.rb bugzilla cherry-pick --username ${env.BZ_USERNAME} --password ${env.BZ_PASSWORD} --version 6.2.0 --milestone 6.2.11 --no-update-repos"
                archive "releases/6.2.0/bugzillas"
          }
    }

}
