@Library("github.com/SatelliteQE/robottelo-ci") _

pipeline {
    agent { label 'sat6-rhel7' }
    options {
        buildDiscarder(logRotator(numToKeepStr:'32'))
    }
    environment {
        EXP_SUBS_FILE='config/robottelo-manifest-content.conf'
    }
    stages {
        stage('Setup Environment') {
            steps {
                make_venv python: defaults.python
                git defaults.automation_tools
                sh_venv """
                    export PYCURL_SSL_LIBRARY=\$(curl -V | sed -n 's/.*\\(NSS\\|OpenSSL\\).*/\\L\\1/p')
                    pip install -r requirements.txt
                """
            }
        }

        stage('Build') {
            steps {
                configFileProvider(
                    [configFile(fileId: 'bc5f0cbc-616f-46de-bdfe-2e024e84fcbf', variable: 'CONFIG_FILES')]) {
                    sshagent (credentials: ['id_hudson_rsa']) {
                        load('config/fake_manifest.groovy')
                        load('config/subscription_config.groovy')
                        ansiColor('xterm') {
                        sh_venv '''
                            source ${CONFIG_FILES}
                            fab -D -H "root@${MANIFEST_SERVER_HOSTNAME}" relink_manifest:"url=${SM_URL}","consumer=${CONSUMER}","user=${RHN_USERNAME}","password=${RHN_PASSWORD}","exp_subs_file=${env.EXP_SUBS_FILE}"
                            '''
                         }
                    }
                }
            }
        }
    }
    post {
    failure {
        send_automation_email "failure"
    }
    fixed {
        send_automation_email "fixed"
    }
    }
}
