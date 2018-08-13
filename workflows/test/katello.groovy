def plugin_name = 'katello'

def version_map = branch_map[env.gitlabTargetBranch]
def ruby = version_map['ruby']

node('sat6-rhel7') {

    stage('Setup Git Repos') {

        deleteDir()

        dir('foreman') {
            gitlab_clone('foreman')
        }

        dir('plugin') {
            gitlab_clone_and_merge(plugin_name)
        }

    }

    stage('Configure Environment') {

        dir('foreman') {
            configure_foreman_environment()
        }

    }

    stage('Configure Database') {

        dir('foreman') {
            setup_foreman(ruby)
        }

    }

    stage('Setup plugin') {

        dir('foreman') {
            setup_plugin(plugin_name, ruby)
        }

    }

    stage('Run Tests') {

        dir('foreman') {
            try {

                gitlabCommitStatus {
                    withRVM(['bundle exec rake jenkins:katello TESTOPTS="-v" --trace'], ruby)
                    withRVM(['bundle exec rake db:drop db:create db:migrate'], ruby)
                    withRVM(['bundle exec rake db:seed'], ruby)
                }

            } finally {

                archive "Gemfile.lock pkg/*"

                cleanup(ruby)

            }
        }
    }

}
