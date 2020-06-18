@Library("github.com/SatelliteQE/robottelo-ci") _

pipeline {
    agent { label 'sat6-rhel7' }
    environment {
        OS_VERSION = '7'
        DISTRO = 'rhel7'
        ANSIBLE_HOST_KEY_CHECKING = 'False'
    }
    options {
        buildDiscarder(logRotator(numToKeepStr:'32'))
    }
    stages {
        stage('Setup Environment') {
            steps {
                script {
                    make_venv python: defaults.python
                    currentBuild.displayName = "#${env.BUILD_NUMBER} ${SERVER_HOSTNAME} ${env.BUILD_LABEL}"
                    checkout([$class: 'GitSCM', branches: [[name: '*/${FAM_BRANCH}']],
                        userRemoteConfigs: [[url: '${FAM_REPO}']]])
                    sh_venv '''
                        make test-setup
                    '''
                }
            }
        }
        stage('Source Config and Variables') {
            steps {
                script {
                    configFileProvider(
                        [configFile(fileId: 'bc5f0cbc-616f-46de-bdfe-2e024e84fcbf', variable: 'CONFIG_FILES')]) {
                            sh_venv '''
                                source ${CONFIG_FILES}
                            '''
                            load('config/sat6_repos_urls.groovy')
                            load('config/subscription_config.groovy')
                            sh_venv '''
                                cp tests/test_playbooks/vars/server.yml.example  tests/test_playbooks/vars/server.yml
                                sed -i "s/foreman.example.com/${SERVER_HOSTNAME}/g" tests/test_playbooks/vars/server.yml
                            '''
                        }
                    }
                }
            }

        stage("Pre-requisite and Setup for testing") {
            steps {
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: 'id_hudson_rsa', keyFileVariable: 'identity', passphraseVariable: '', usernameVariable: 'userName')]) {
                        if (env.RELEASED_FAM == 'true') {
                            sh_venv '''
                            sed -i "s|plugins/|/usr/share/ansible/collections/ansible_collections/redhat/satellite/plugins/|g" ansible.cfg
                            '''
                        }
                    }
                }
            }
        }

        stage("Testing") {
            steps {
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: 'id_hudson_rsa', keyFileVariable: 'identity', passphraseVariable: '', usernameVariable: 'userName')]) {
                        def command = 'pytest -sv -n4 --boxed --junit-xml=foreman-results.xml -k"not check_mode"'
                        try {
                            if (env.REPLAY == 'true') {
                                sh_venv command + 'tests/'
                            }
                            else {
                                sh_venv '''
                                rm tests/test_playbooks/fixtures/*.yml
                                '''
                                sh_venv command + '--record tests/'
                            }
                        }
                        catch(all) {
                            currentBuild.result = 'UNSTABLE'
                        }
                    }
                }
            }
        }

        stage("Post Testing - archiving casettes") {
            steps {
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: 'id_hudson_rsa', keyFileVariable: 'identity', passphraseVariable: '', usernameVariable: 'userName')]) {
                        remote = [: ]
                        remote.name = "Satellite Server "
                        remote.allowAnyHosts = true
                        remote.host = SERVER_HOSTNAME
                        remote.user = userName
                        remote.identityFile = identity
                        sshCommand remote: remote, command: 'tar -czvf cassettes.tar.gz tests/test_playbooks/fixtures'
                    }
                }
            }
        }

    }

    post {
        always {
            junit(testResults: '*-results.xml', allowEmptyResults: true)
            archiveArtifacts(artifacts: 'cassettes.tar.gz', allowEmptyArchive: true)
            //TBA send_report_email "foreman-ansible-modules"
        }
    }
}
