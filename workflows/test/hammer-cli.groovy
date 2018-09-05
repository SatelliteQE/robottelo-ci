def version_map = branch_map[env.gitlabTargetBranch]
def ruby = version_map['ruby']

node('sat6-build') {

    stage('Setup Git Repos') {

        deleteDir()
        gitlab_clone_and_merge(plugin_name)

    }

    stage('Run Tests') {

        if (plugin_name == 'hammer_cli_katello') {
            test_command = 'rake'
        } else {
            test_command = 'rake ci:setup:minitest test'
        }

        try {

            gitlabCommitStatus {
                withRVM(['bundle install'], ruby)
                withRVM(["bundle exec ${test_command} TESTOPTS='-v'"], ruby)
            }

        } finally {

            archive "Gemfile.lock"

            cleanup_rvm('', ruby)

        }
    }

}
