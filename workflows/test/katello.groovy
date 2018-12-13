def plugin_name = 'katello'

def version_map = branch_map[env.gitlabTargetBranch]
def ruby = version_map['ruby']

pipeline {
    options {
        timestamps()
        timeout(time: 2, unit: 'HOURS')
        ansiColor('xterm')
        buildDiscarder(logRotator(numToKeepStr: '15'))
    }

    agent { label 'sat6-build' }

    stages {
        stage('Setup Git Repos') {
            steps {
                deleteDir()

                dir('foreman') {
                    gitlab_clone('foreman')
                }

                dir('plugin') {
                    gitlab_clone_and_merge(plugin_name)
                }
            }
        }

        stage('Configure Environment') {
            steps {
                dir('foreman') {
                    configure_foreman_environment()
                }
            }
        }

        stage('Configure Database') {
            steps {
                dir('foreman') {
                    setup_foreman(ruby)
                }
            }
        }

        stage('Setup plugin') {
            steps {
                dir('foreman') {
                    setup_plugin(plugin_name, ruby)
                }
            }
        }

        stage('Run Tests') {
            parallel {
                stage('tests') {
                    steps {
                        dir('foreman') {
                            gitlabCommitStatus(name: "tests") {
                                withRVM(['bundle exec rake jenkins:katello TESTOPTS="-v" --trace'], ruby)
                            }
                        }
                    }
                }
                stage('rubocop') {
                    steps {
                        dir('foreman') {
                            gitlabCommitStatus(name: "rubocop") {
                                withRVM(['bundle exec rake katello:rubocop TESTOPTS="-v" --trace'], ruby)
                            }
                        }
                    }
                }
                stage('react-ui') {
                    when {
                        expression { fileExists('plugin/package.json') }
                    }
                    steps {
                        gitlabCommitStatus(name: "react-ui") {
                            dir('plugin') {
                                sh "npm install npm"
                                sh "node_modules/.bin/npm install"
                                sh 'npm run lint'
                                sh 'npm test'
                            }
                        }
                    }
                }
                stage('angular-ui') {
                    steps {
                        gitlabCommitStatus(name: "angular-ui") {
                            dir('foreman') {
                                withRVM(['bundle show bastion > bastion-version'], ruby)

                                script {
                                    bastion_install = readFile('bastion-version')
                                    bastion_version = bastion_install.split('bastion-')[1]
                                    echo bastion_install
                                    echo bastion_version
                                }
                            }

                            sh "cp -rf \$(cat foreman/bastion-version) plugin/engines/bastion_katello/bastion-${bastion_version}"
                            dir('plugin/engines/bastion_katello') {
                                sh "npm install npm"
                                sh "node_modules/.bin/npm install bastion-${bastion_version}"
                                sh "TZ=UTC grunt ci"
                            }
                        }
                    }
                }
                stage('assets-precompile') {
                    steps {
                        dir('foreman') {
                            gitlabCommitStatus(name: "assets-precompile") {
                                sh "npm install npm"
                                withRVM(["bundle exec node_modules/.bin/npm install"], ruby)
                                withRVM(["bundle exec rake plugin:assets:precompile[${plugin_name}] RAILS_ENV=production --trace"], ruby)
                            }
                        }
                    }
                }
            }
            post {
                always {
                    dir('foreman') {
                        archiveArtifacts artifacts: "Gemfile.lock, log/test.log, pkg/*"
                        junit keepLongStdio: true, testResults: 'jenkins/reports/unit/*.xml', allowEmptyResults: true
                    }
                }
            }
        }
        stage('Test db:seed') {
            steps {

                dir('foreman') {

                    gitlabCommitStatus(name: "db:seed") {
                        withRVM(['bundle exec rake db:drop || true'], ruby)
                        withRVM(['bundle exec rake db:create'], ruby)
                        withRVM(['bundle exec rake db:migrate'], ruby)
                        withRVM(['bundle exec rake db:seed'], ruby)
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
            dir('foreman') {
                cleanup(ruby)
            }
        }
    }
}
