node('rvm') {

    stage("Setup Environment") {

        deleteDir()
        gitlab_clone_and_merge('runcible')

    }

    stage('Setup RVM') {

        configureRVM('2.3')

    }

    stage('Tests') {

        try {

            gitlabCommitStatus {
                withRVM(["bundle install"], '2.3')
                withRVM(["bundle exec rake rubocop"], '2.3')
                withRVM(["bundle exec rake test"], '2.3')
            }

        } finally {

            archive "Gemfile.lock pkg/*"
            cleanupRVM('2.3')

        }

    }

}
