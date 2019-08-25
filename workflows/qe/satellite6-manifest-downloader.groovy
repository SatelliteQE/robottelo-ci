@Library("github.com/SatelliteQE/robottelo-ci") _

pipeline {
    agent { label 'sat6-rhel7' }
    options {
        buildDiscarder(logRotator(numToKeepStr:'32'))
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
                        ansiColor('xterm') {
                        sh_venv '''
                            source ${CONFIG_FILES}
                            source config/fake_manifest.conf
                            source config/subscription_config.conf
                            export EXP_SUBS_FILE=config/robottelo-manifest-content.conf
                            fab -D -H "root@${MANIFEST_SERVER_HOSTNAME}" relink_manifest
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
