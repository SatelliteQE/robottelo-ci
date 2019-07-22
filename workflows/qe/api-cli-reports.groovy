@Library("github.com/SatelliteQE/robottelo-ci") _

pipeline {
    agent { label 'sat6-rhel' }
    stages {
        stage('Virtualenv') {
            steps {
                make_venv python: defaults.python
            }
        }

        stage('Install APIx') {
            steps {
                git defaults.apix
                sh_venv """
                    git clone https://github.com/JacobCallahan/apix.git
                """
            }
        }

        stage('Gather API Information') {
            steps {
                sh_venv '''
                    apix explore -n satellite -u https://$(SATELLITE_SERVER_HOSTNAME)/ -v $(SATELLITE_VERSION) --data-dir $(DATA_DIR)
                    apix explore -n satellite -u https://$(SATELLITE_SERVER_HOSTNAME)/ -v $(SATELLITE_VERSION) --compact --data-dir $(DATA_DIR)
                    apix diff -n satellite -l $(SATELLITE_VERSION) --data-dir $(DATA_DIR)
                    apix diff -n satellite -l $(SATELLITE_VERSION) --compact --data-dir $(DATA_DIR)
                '''
            }
        }

        stage('Generate API Library') {
            steps {
                sh_venv '''
                    apix makelib -n satellite -l $(SATELLITE_VERSION) -t advanced --data-dir $(DATA_DIR)
                    cd ..
                '''
            }
        }

        stage('Install CLIx') {
            steps {
                git defaults.clix
                sh_venv """
                    pip install .
                """
            }
        }

        stage('Gather CLI Information') {
            steps {
                sh_venv '''
                    clix explore -n hammer -t $(SATELLITE_SERVER_HOSTNAME) -v $(SATELLITE_VERSION) -a root/$(ROOT_PASSWORD) --max-session 100 --data-dir $(DATA_DIR)
                    clix explore -n hammer -t $(SATELLITE_SERVER_HOSTNAME) -v $(SATELLITE_VERSION) -a root/$(ROOT_PASSWORD) --max-session 100 --compact --data-dir $(DATA_DIR)
                    clix diff -n hammer -l $(SATELLITE_VERSION) --data-dir $(DATA_DIR)
                    clix diff -n hammer -l $(SATELLITE_VERSION) --compact --data-dir $(DATA_DIR)
                '''
            }
        }

        stage('Generate CLI Library') {
            steps {
                sh_venv '''
                    clix makelib -n hammer -l $(SATELLITE_VERSION) --data-dir $(DATA_DIR)
                    cd ..
                '''
            }
        }

        stage('Install Robottelo') {
            steps {
                git defaults.robottelo
                sh_venv """
                    export PYCURL_SSL_LIBRARY=\$(curl -V | sed -n 's/.*\\(NSS\\|OpenSSL\\).*/\\L\\1/p')
                    pip install -r requirements.txt
                    pip install .
                """
            }
        }

        stage('Install Plinko') {
            steps {
                git defaults.plinko
                sh_venv """
                    pip install .
                """
            }
        }

        stage('Generate Plinko Reports') {
            steps {
                sh_venv '''
                    plinko deep --apix-diff $(DATA_DIR)/apix/APIs/satellite/$(SATELLITE_VERSION)-comp.yaml --test-directory ../robottelo/tests/foreman/api/ --behavior minimal --depth 5
                    plinko deep --clix-diff $(DATA_DIR)/clix/CLIs/hammer/$(SATELLITE_VERSION)-comp.yaml --test-directory ../robottelo/tests/foreman/cli/ --behavior minimal --depth 5
                '''
            }
        }


    }
    post {
        always {
            archiveArtifacts(artifacts: '*.yaml', allowEmptyArchive: true)
        }
    }
}