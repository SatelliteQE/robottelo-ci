node('sat6-build') {

    stage('Setup Git Repos') {

        deleteDir()
        gitlab_clone_and_merge(plugin_name)

    }

    stage('Run Tests') {

        try {

            gitlabCommitStatus {
                withRVM(['bundle install'], 2.0)
                withRVM(['bundle exec rake test TESTOPTS="-v"'], 2.0)
            }

        } finally {

            archive "Gemfile.lock"
            cleanupRVM('2.0')

        }
    }

}
