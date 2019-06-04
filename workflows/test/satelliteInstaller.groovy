node('rvm') {

    stage("Setup Environment") {

        deleteDir()
        gitlab_clone_and_merge('satellite-installer')

    }

    stage('Setup RVM') {

        configureRVM('2.5')

    }

    stage('Tests') {

        try {

            gitlabCommitStatus {
                withRVM(["bundle install"], '2.5')
                withRVM(["bundle exec rake"], '2.5')
            }

        } finally {

            archive "Gemfile.lock pkg/*"
            cleanupRVM()

        }

    }

}
