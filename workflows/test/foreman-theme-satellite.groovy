def plugin_name = 'foreman_theme_satellite'

node('sat6-rhel7') {

    snapperStage('Setup Git Repos') {

        deleteDir()
        dir('foreman') {
            gitlab_clone('foreman')
        }
        dir('plugin') {
            gitlab_clone_and_merge(plugin_name)
        }

    }

    snapperStage('Configure Environment') {

        dir('foreman') {
            configure_foreman_environment()
        }

    }

    snapperStage('Configure Database') {

        dir('foreman') {
            setup_foreman()
        }

    }

    snapperStage('Setup plugin') {

        dir('foreman') {
            setup_plugin(plugin_name)
        }

    }

    snapperStage('Run Tests') {

        dir('foreman') {
            try {

                gitlabCommitStatus {
                    withRVM(['bundle exec rake test:foreman_theme_satellite'], 2.2)
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
