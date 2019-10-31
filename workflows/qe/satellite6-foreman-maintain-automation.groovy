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
                    def FM_VER = sh_venv(
                        script : "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${SERVER_HOSTNAME} rpm --queryformat='%{VERSION}' -q rubygem-foreman_maintain",
                        returnStdout : true
                    )
                    currentBuild.displayName = "#${env.BUILD_NUMBER} ${SERVER_HOSTNAME} Ver."+FM_VER+" ${env.BUILD_LABEL}"
                    git defaults.testfm
                    sh_venv '''
                        pip install -r requirements.txt
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
                                source config/testfm.conf
                                cp testfm.properties.sample testfm.properties
                                cp testfm/inventory.sample testfm/inventory
                                sed -i "s/<server_hostname>/${SERVER_HOSTNAME}/g" testfm/inventory
                            '''
                            if ("${COMPONENT}" != "CAPSULE") {
                                propargs = [
                                    'RHN_USERNAME' : RHN_USERNAME,
                                    'RHN_PASSWORD' : env.RHN_PASSWORD,
                                    'RHN_POOLID' : RHN_POOLID,
                                    'DOGFOOD_ORG' : DOGFOOD_ORG,
                                    'DOGFOOD_ACTIVATIONKEY' : env.DOGFOOD_ACTIVATIONKEY,
                                    'DOGFOOD_URL' : DOGFOOD_URL,
                                    'HOTFIX_URL' : env.HOTFIX_URL
                                ]
                                parse_ini ini_file: "${WORKSPACE}//testfm.properties", properties: propargs
                            }
                        }
                    }
                }
            }

        stage("Pre-requisite and Setup for testing") {
            steps {
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: 'id_hudson_rsa', keyFileVariable: 'identity', passphraseVariable: '', usernameVariable: 'userName')]) {
                        if ("${TEST_UPSTREAM}" == "true") {
                            sh_venv 'sed -i "s/foreman-maintain {0} {1} {2}/./foreman_maintain/bin/foreman-maintain {0} {1} {2}/g" testfm/base.py'
                            remote = [: ]
                            remote.name = "Satellite Server ${SERVER_HOSTNAME}"
                            remote.allowAnyHosts = true
                            remote.host = SERVER_HOSTNAME
                            remote.user = userName
                            remote.identityFile = identity
                            sshCommand remote: remote, command: "rm foreman_maintain/ -rvf"
                            sshCommand remote: remote, command: "git clone https://github.com/theforeman/foreman_maintain.git"
                            if ("${TEST_OPEN_PR}" == 'true') {
                                sshCommand remote: remote, command: "cd foreman_maintain; git fetch origin pull ${PR_NUMBER}/head:${BRANCH_NAME}; git checkout ${BRANCH_NAME}"
                            }
                        }

                        if ("${SATELLITE_VERSION}" != "6.3" || "${SATELLITE_VERSION}" != "6.4" && "${TEST_UPSTREAM}" == "false") {
                            sh_venv 'sed -i "s/foreman-maintain {0} {1} {2}/satellite-maintain {0} {1} {2}/g" testfm/base.py'
                        }

                        if ("${COMPONENT}" == "capsule") {
                            def PYTEST_MARKS = 'capsule'
                        }
                        else {
                            def PYTEST_MARKS = "${PYTEST_MARKS}"
                        }
                    }
                }
            }
        }

        stage("Testing") {
            steps {
                script {
                    def command = 'pytest -sv --junit-xml=foreman-results.xml --ansible-host-pattern server --ansible-user root --ansible-inventory testfm/inventory '
                    try {
                        if ("${PYTEST_OPTIONS}") {
                            sh_venv command + '${PYTEST_OPTIONS}'
                        }
                        else if (PYTEST_MARKS) {
                            sh_venv command + 'tests/ -m ${PYTEST_MARKS}'
                        }
                        else {
                            sh_venv command + 'tests/'
                        }
                    }
                    catch(all) {
                        currentBuild.result = 'UNSTABLE'
                    }
                }
            }
        }

        stage("Post Testing - Check Errors in Logs") {
            steps {
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: 'id_hudson_rsa', keyFileVariable: 'identity', passphraseVariable: '', usernameVariable: 'userName')]) {
                        remote = [: ]
                        remote.name = "Satellite Server "
                        remote.allowAnyHosts = true
                        remote.host = SERVER_HOSTNAME
                        remote.user = userName
                        remote.identityFile = identity

                        if ("${TEST_UPSTREAM}" != "true") {
                            sshCommand remote: remote, command: 'cat /var/log/foreman-maintain/foreman-maintain.log | grep -i error'
                        }
                        else {
                            sshCommand remote: remote, command: 'cat ~/foreman_maintain/logs/foreman-maintain.log | grep -i error'
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            send_report_email "foreman-maintain"
        }
    }
}
