@Library("github.com/SatelliteQE/robottelo-ci") _

pipeline {
    agent { label 'sat6-rhel7' }
    environment {
        OS = "rhel7"
        DISTRO = "rhel7"
        FROM_VERSION=" "
    }
    options {
        buildDiscarder(logRotator(numToKeepStr:'32'))
    }
    stages {
        stage('Setup environment') {
            steps {
                make_venv python: defaults.python
                git defaults.satellite6_upgrade
            }
        }
        stage('Install requirements') {
            steps {
                sh_venv '''
                    export PYCURL_SSL_LIBRARY=\$(curl -V | sed -n 's/.*\\(NSS\\|OpenSSL\\).*/\\L\\1/p')
                    pip install -r requirements.txt
                    '''
            }
        }
        stage('Build') {
            steps {
                ansiColor('xterm') {
                configFileProvider(
                    [configFile(fileId: 'bc5f0cbc-616f-46de-bdfe-2e024e84fcbf', variable: 'CONFIG_FILES')]) {
                    sshagent (credentials: ['id_hudson_rsa']) {
                    sh_venv 'source ${CONFIG_FILES}'
                    load('config/sat6_upgrade.groovy')
                    sh_venv 'fab -H ' + DOCKER_VM + ' -u root docker_cleanup_containers'
                    }
                }
                }
            }
        }
    }
}
