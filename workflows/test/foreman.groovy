node('sat6-rhel7') {

    stage('Setup Git Repos') {

        deleteDir()
        gitlab_clone_and_merge('foreman')

    }

    stage('Configure Environment') {

        configure_foreman_environment()

    }

    stage('Configure Database') {

        setup_foreman(get_ruby_version(branch_map))

    }

    stage('Run Tests') {

        try {

            gitlabCommitStatus {
                withRVM(['bundle exec rake jenkins:unit jenkins:integration TESTOPTS="-v"'], get_ruby_version(branch_map))
            }

        } finally {

            archive "Gemfile.lock pkg/*"
            junit keepLongStdio: true, testResults: 'jenkins/reports/unit/*.xml'

            cleanup(get_ruby_version(branch_map))

        }
    }

}
