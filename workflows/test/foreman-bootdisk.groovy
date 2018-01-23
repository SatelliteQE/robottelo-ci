def plugin_name = 'foreman_bootdisk'

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
            setup_foreman()
        }

    }

    stage('Setup plugin') {

        dir('foreman') {
            setup_plugin(plugin_name)
        }

    }

    stage('Run Tests') {

        dir('foreman') {
            try {

                gitlabCommitStatus {
                    withRVM(['bundle exec rake test:foreman_bootdisk'], 2.2)
                    withRVM(['bundle exec rake db:drop db:create db:migrate'], 2.2)
                    withRVM(['bundle exec rake db:seed'], 2.2)
                }

            } finally {

                archive "Gemfile.lock pkg/*"

                cleanup()

            }
        }
    }

}
