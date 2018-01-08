def plugin_name = 'foreman_theme_satellite'

if (env.gitlabTargetBranch == 'master' ) {
    ruby = '2.4'
} else {
    ruby = '2.2'
}

node('sat6-rhel7') {

    snapperStage('Setup Git Repos') {

        deleteDir()

        dir('foreman') {
            if (env.gitlabTargetBranch == 'master' ) {
                git url: "https://github.com/theforeman/foreman.git", branch: "develop"
            } else {
                gitlab_clone('foreman')
            }
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
            setup_foreman(ruby)
        }

    }

    snapperStage('Setup plugin') {

        dir('foreman') {
            setup_plugin(plugin_name, ruby)
        }

    }

    snapperStage('Run Tests') {

        dir('foreman') {
            try {

                gitlabCommitStatus {
                    withRVM(['bundle exec rake test:foreman_theme_satellite'], ruby)
                    withRVM(['bundle exec rake db:drop db:create db:migrate'], ruby)
                    withRVM(['bundle exec rake db:seed'], ruby)
                }

            } finally {

                archive "Gemfile.lock pkg/*"

                cleanup()

            }
        }
    }

}
