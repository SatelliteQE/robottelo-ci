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
                        sh_venv '''
                            source ${CONFIG_FILES}
                            source config/provisioning_environment.conf
                            source config/installation_environment.conf
        
                            HYPERVISORS=${HYPERVISORS:-$PROVISIONING_HOSTS}
                            set $HYPERVISORS # we can use 1st hypervisors as $1
                            fab -A -D -H "root@$1" "deploy_baseimage_by_url:$OS_URL,hypervisors=$HYPERVISORS,auth_keys_url=$AUTH_KEYS_URL,dns_server=$DNS_SERVER,disable_ipv6=$DISABLE_IPV6"
                        '''
                    }
                }
            }
        }

    }
    post {
        always {
            junit(testResults: '*-results.xml', allowEmptyResults: true)
            archiveArtifacts(artifacts: '*.log', allowEmptyArchive: true)
        }
    }
}
