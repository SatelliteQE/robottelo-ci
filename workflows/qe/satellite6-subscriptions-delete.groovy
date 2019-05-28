@Library("github.com/SatelliteQE/robottelo-ci") _

pipeline {
    agent { label 'sat6-rhel' }
    stages {
        stage('Virtualenv') {
            steps {
                make_venv python: 'python' // run with python2
            }
        }

        stage('Pip Install') {
            steps {
                sh_venv """
                    pip install requests
                """
            }
        }
    
        stage('Source Variables') {
            steps {
                configFileProvider(
                    [configFile(fileId: 'bc5f0cbc-616f-46de-bdfe-2e024e84fcbf', variable: 'CONFIG_FILES')]) {
                    sshagent (credentials: ['id_hudson_rsa']) {
                        sh_venv '''
                            source ${CONFIG_FILES}
                            source config/subscription_config.conf
                        '''
                    }
                }
            }
        }
        stage('Build') {
            steps {
                configFileProvider(
                    [configFile(fileId: '14cc16d0-7390-4956-898c-a08b93b0e43c', variable: 'TOOLS')]) {
                    sshagent (credentials: ['id_hudson_rsa']) {
                        sh_venv '''
                            python tools/satellite6_subscriptions_delete.py
                        '''
                    }
                }
            }
        }
    }
}
