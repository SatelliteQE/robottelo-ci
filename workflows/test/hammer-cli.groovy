def version_map = branch_map[env.gitlabTargetBranch]
def ruby = version_map['ruby']

pipeline {

    agent { label 'sat6-build' }

    options {
      ansiColor('xterm')
      disableConcurrentBuilds()
      timestamps()
    }

    stages {

      stage('Setup Git Repos') {
        steps {
          deleteDir()
          gitlab_clone_and_merge(plugin_name)
        }
      }

      stage('Setup RVM') {
        steps {
          configureRVM(ruby)
        }
      }

      stage('Run Tests') {
        steps {
          script {
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

                cleanupRVM(ruby)

            }
          }
        }
      }
    }
}
