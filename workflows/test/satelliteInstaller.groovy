node('rvm') {

    stage("Setup Environment") {

        deleteDir()
        gitlab_clone_and_merge('satellite-installer')

    }

    stage('Setup RVM') {

        configureRVM()

    }

    stage('Tests') {

        try {

            gitlabCommitStatus {
                withRVM(["bundle install"])
                withRVM(["bundle exec rake"])
            }

        } finally {

            archive "Gemfile.lock pkg/*"
            cleanupRVM()

        }

    }

}
