def ruby = '2.4'

pipeline {
    agent { label 'rvm' }

    stages {
        stage('Setup Git Repos') {
            steps {
                gitlab_clone_and_merge('satellite6/ohsnap')
            }
        }

        stage('Configure Environment') {
            parallel {
                stage('bundle') {
                    steps {
                        withRVM(['bundle install'], ruby)
                    }
                }
                stage('npm') {
                    steps {
                        sh "npm install"
                    }
                }
            }
        }

        stage('Run Tests') {
            parallel {
                stage('unittests') {
                    steps {
                        gitlabCommitStatus(name: 'unittests') {
                            withRVM(['bundle exec rake'], ruby)
                        }
                    }
                }
                stage('webpack') {
                    steps {
                        gitlabCommitStatus(name: 'webpack') {
                            sh "./node_modules/webpack/bin/webpack.js --bail"
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
            archiveArtifacts artifacts: "Gemfile.lock, package-lock.json"
            step([$class: 'CoberturaPublisher', coberturaReportFile: 'coverage/coverage.xml'])
            cleanup(ruby)
            deleteDir()
        }
    }
}

def cleanup(ruby = my_ruby) {
    try {

        sh "rm -rf node_modules/"

    } finally {

        cleanup_rvm(ruby)

    }
}
