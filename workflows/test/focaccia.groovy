def ruby = '2.4'

pipeline {
    agent { label 'rvm' }

    stages {
        stage('Setup Git Repos') {
            steps {
                gitlab_clone_and_merge('satellite6/focaccia')
            }
        }

        stage('Configure Environment') {
            parallel {
                stage('bundle') {
                    steps {
                        configureRVM(ruby)
                        withRVM(['bundle install'], ruby)
                    }
                }
            }
        }

        stage('Run Tests') {
            parallel {
                stage('tests') {
                    steps {
                        gitlabCommitStatus(name: 'tests') {
                            withRVM(['bundle exec rspec'], ruby)
                        }
                    }
                }
                stage('linting') {
                    steps {
                        gitlabCommitStatus(name: 'linting') {
                            withRVM(['bundle exec rubocop'], ruby)
                        }
                    }
                }
            }
        }
    }

    post {
        failure {
            updateGitlabCommitStatus name: 'jenkins', state: 'failed'
        }
        success {
            updateGitlabCommitStatus name: 'jenkins', state: 'success'
        }
        always {
            archiveArtifacts artifacts: "Gemfile.lock"
            cleanupRVM(ruby)
            deleteDir()
        }
    }
}
