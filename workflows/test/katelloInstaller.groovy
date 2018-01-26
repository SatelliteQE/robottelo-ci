node('rvm') {

    stage("Setup Environment") {

        deleteDir()
        gitlab_clone_and_merge('katello-installer')

    }

    stage('Tests') {

        try {

            gitlabCommitStatus {
                withRVM(["gem install bundler"])
                withRVM(["bundle install"])
                withRVM(["FOREMAN_BRANCH=1.15-stable bundle exec rake"])
            }

        } finally {

            archive "Gemfile.lock pkg/*"
            cleanup_rvm()

        }

    }

}
