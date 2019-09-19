@Library("github.com/SatelliteQE/robottelo-ci") _

pipeline {
    agent { label 'sat6-rhel' }
    stages {
        stage('Gather API Information') {
            steps {
                git defaults.apix
                dir("apix") {
                    make_venv python: defaults.python
                    sh_venv '''
                        cd ..
                        pip install .
                        apix explore -n satellite -u https://${SATELLITE_SERVER_HOSTNAME}/ -v ${SATELLITE_VERSION} --data-dir ${DATA_DIR}
                        apix explore -n satellite -u https://${SATELLITE_SERVER_HOSTNAME}/ -v ${SATELLITE_VERSION} --compact --data-dir ${DATA_DIR}
                        apix diff -n satellite -l ${SATELLITE_VERSION} --data-dir ${DATA_DIR}
                        apix diff -n satellite -l ${SATELLITE_VERSION} --compact --data-dir ${DATA_DIR}
                        apix makelib -n satellite -v ${SATELLITE_VERSION} -t advanced --data-dir ${DATA_DIR}
                    '''
                }
            }
        }

        stage('Gather CLI Information') {
            steps {
                git defaults.clix
                dir("clix"){
                    make_venv python: defaults.python
                    sh_venv '''
                        cd ..
                        pip install .
                        clix explore -n hammer -t ${SATELLITE_SERVER_HOSTNAME} -v ${SATELLITE_VERSION} -a root/${ROOT_PASSWORD} --max-session 100 --data-dir ${DATA_DIR}
                        clix explore -n hammer -t ${SATELLITE_SERVER_HOSTNAME} -v ${SATELLITE_VERSION} -a root/${ROOT_PASSWORD} --max-session 100 --compact --data-dir ${DATA_DIR}
                        clix diff -n hammer -l ${SATELLITE_VERSION} --data-dir ${DATA_DIR}
                        clix diff -n hammer -l ${SATELLITE_VERSION} --compact --data-dir ${DATA_DIR}
                        clix makelib -n hammer -v ${SATELLITE_VERSION} --data-dir ${DATA_DIR}
                    '''
                }
            }
        }

        stage('Install Robottelo') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/master']],
                    doGenerateSubmoduleConfigurations: false,
                    extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'robottelo']],
                    submoduleCfg: [],
                    userRemoteConfigs: [[url: 'https://github.com/SatelliteQE/robottelo']]
                ])
                sh_venv """
                    cd robottelo
                    export PYCURL_SSL_LIBRARY=\$(curl -V | sed -n 's/.*\\(NSS\\|OpenSSL\\).*/\\L\\1/p')
                    pip install -r requirements.txt
                    pip install .
                """
                }
            }

        stage('Generate Plinko Reports') {
            steps {
                git defaults.plinko
                dir("plinko") {
                    make_venv python: defaults.python
                    sh_venv '''
                        cd ..
                        pip install .
                        plinko deep --name robottelo --apix-diff ${DATA_DIR}APIs/satellite/${SATELLITE_VERSION}-comp.yaml --test-directory robottelo/tests/foreman/api/ --behavior minimal --depth 5
                        plinko deep --name robottelo --clix-diff ${DATA_DIR}CLIs/hammer/${SATELLITE_VERSION}-comp.yaml --test-directory robottelo/tests/foreman/cli/ --behavior minimal --depth 5
                    '''
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts(artifacts: '*.yaml', allowEmptyArchive: true)
        }
    }
}