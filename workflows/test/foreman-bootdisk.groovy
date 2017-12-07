node('sat6-rhel7') {

    snapperStage('Setup Git Repos') {

        deleteDir()
        gitlab_clone_and_merge('foreman')

    }

    snapperStage('Configure Environment') {

        configure_foreman_environment()

    }

    snapperStage('Configure Database') {

        setup_foreman()

    }

    snapperStage('Run Tests') {

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
