node('rvm') {

    snapperStage("Setup Environment") {

        deleteDir()
        gitlab_clone_and_merge('katello-installer')

    }

    snapperStage('Tests') {

        try {

            gitlabCommitStatus {
                withRVM(["gem install bundler"])
                withRVM(["bundle install"])
                withRVM(["FOREMAN_BRANCH=1.15-stable bundle exec rake"])
            }

        } finally {

            archive "pkg/*"
            cleanup_rvm()

        }

    }

}
