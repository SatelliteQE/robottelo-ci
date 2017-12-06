node('rvm') {

    snapperStage("Setup Environment") {

        deleteDir()
        gitlab_clone_and_merge('runcible')

    }

    snapperStage('Tests') {

        try {

            gitlabCommitStatus {
                withRVM(["gem install bundler"], '2.3')
                withRVM(["bundle install"], '2.3')
                withRVM(["bundle exec rake rubocop"], '2.3')
                withRVM(["bundle exec rake test"], '2.3')
            }

        } finally {

            archive "pkg/*"
            cleanup_rvm(ruby: "2.3")

        }

    }

}
