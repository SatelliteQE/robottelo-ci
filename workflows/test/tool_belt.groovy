def ruby = '2.4'

pipeline {
    agent { label 'rvm' }

    stages {
        stage('Setup Git Repos') {
            steps {
                gitlab_clone_and_merge('satellite6/tool_belt')
            }
        }

        stage('Configure Environment') {
            steps {
                configureRVM(ruby)
                withRVM(['bundle install'], ruby)
            }
        }

        stage('Run Tests') {
            steps {
                gitlabCommitStatus(name: 'unittests') {
                    withRVM(['bundle exec rake'], ruby)
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
            step([$class: 'CoberturaPublisher', coberturaReportFile: 'coverage/coverage.xml'])
            cleanupRVM(ruby)
            deleteDir()
        }
    }
}
