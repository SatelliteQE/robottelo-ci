node('rhel') {

    snapperStage("Setup Environment") {

        deleteDir()
        gitlab_clone_and_merge('foreman-installer')

    }

    snapperStage('Tests') {

        try {

            withRVM(["gem install bundler"])
            withRVM(["bundle install"])
            withRVM(["bundle exec rake"])

        } finally {

            archive "pkg/*"
            cleanup_rvm()

        }

    }

}
