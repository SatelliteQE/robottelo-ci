node('rvm') {

    stage("Setup Environment") {

        deleteDir()
        gitlab_clone_and_merge('satellite-installer')

    }

    stage('Tests') {

        try {

            gitlabCommitStatus {
                withRVM(["gem install bundler"])
                withRVM(["bundle install"])
                withRVM(["bundle exec rake"])
            }

        } finally {

            archive "pkg/*"
            cleanup_rvm()

        }

    }

}
