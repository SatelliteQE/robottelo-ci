node('rvm') {

    stage("Setup Environment") {

        deleteDir()
        gitlab_clone_and_merge('foreman-installer')

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
