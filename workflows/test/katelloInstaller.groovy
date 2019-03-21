def version_map = branch_map[env.gitlabTargetBranch]
def ruby = version_map['ruby']

node('rvm') {

    stage("Setup Environment") {

        deleteDir()
        gitlab_clone_and_merge('katello-installer')

    }

    stage('Setup RVM') {

        configureRVM(ruby)

    }

    stage('Tests') {

        try {

            gitlabCommitStatus {
                withRVM(["bundle install"], ruby)
                withRVM(["bundle exec rake"], ruby)
            }

        } finally {

            archive "Gemfile.lock pkg/*"
            cleanupRVM(ruby)

        }

    }

}
