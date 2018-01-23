node('sat6-rhel7') {

    stage('Setup Git Repos') {

        deleteDir()
        gitlab_clone_and_merge('foreman')

    }

    stage('Configure Environment') {

        configure_foreman_environment()

    }

    stage('Configure Database') {

        setup_foreman()

    }

    stage('Run Tests') {

        try {

            gitlabCommitStatus {
                withRVM(['bundle exec rake jenkins:unit jenkins:integration TESTOPTS="-v"'], 2.2)
            }

        } finally {

            archive "Gemfile.lock pkg/*"
            junit keepLongStdio: true, testResults: 'jenkins/reports/unit/*.xml'

            cleanup()

        }
    }

}
