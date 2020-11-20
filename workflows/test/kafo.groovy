def version_map = branch_map[env.gitlabTargetBranch]
def ruby = version_map['ruby']

node('rvm') {

    stage("Setup Environment") {

        deleteDir()
        gitlab_clone_and_merge('kafo')

    }

    stage('Setup RVM') {

        configureRVM(ruby)

    }

    stage('Tests') {

        try {

            gitlabCommitStatus {
                withRVM(["bundle install"], ruby)
                withRVM(["bundle exec rake jenkins:unit"], ruby)
            }

        } finally {

            archive "Gemfile.lock pkg/*"
            cleanupRVM()

        }

    }

}
