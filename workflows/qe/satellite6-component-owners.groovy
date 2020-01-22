@Library("github.com/SatelliteQE/robottelo-ci") _

pipeline {
    agent {
        label 'sat6-rhel'
    }
    options {
        buildDiscarder(logRotator(numToKeepStr:'20'))
        disableConcurrentBuilds()
    }
    stages {
        stage('Create Virtualenv') {
            steps {
                make_venv([
                    venv: "${env.WORKSPACE}/venv",
                    python: defaults.python
                ])
            }
        }
        stage('Clone satellite6-reporting repo') {
            steps {
                configFileProvider(
                [configFile(fileId: '4d08176d-ab32-4830-93bc-1cc6e9003b0f', variable: 'SAT6_REPORTING')]) {
                    sh_venv([
                        venv: "${env.WORKSPACE}/venv",
                        script: "source \${SAT6_REPORTING}"
                    ])
                }
            }
        }
        stage('Prepare satellite6-reporting') {
            steps {
                dir("satellite6-reporting") {
                    sh_venv([
                        venv: "${env.WORKSPACE}/venv",
                        script: """
                            pip install -r requirements.txt
                            """
                    ])
                }
            }
        }
        stage('Generate component-owners-map.yaml file') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'mojo', passwordVariable: 'MOJO_PASSWORD', usernameVariable: 'MOJO_USER')]) {
                    dir("satellite6-reporting/component-owners") {
                        sh_venv([
                            venv: "${env.WORKSPACE}/venv",
                            script: com_cmd(MOJO_USER, MOJO_PASSWORD, 'print -f ../../component-owners-map.yaml')
                        ])
                    }
                }
            }
        }
        stage('Update Mojo') {
            when {
                expression { return params.UPDATE_MOJO }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'mojo', passwordVariable: 'MOJO_PASSWORD', usernameVariable: 'MOJO_USER')]) {
                    dir("satellite6-reporting/component-owners") {
                        sh_venv([
                            venv: "${env.WORKSPACE}/venv",
                            script: com_cmd(MOJO_USER, MOJO_PASSWORD, 'update')
                        ])
                    }
                }
            }
        }
        stage('Prepare Robottelo') {
            steps {
                dir("robottelo") {
                    git defaults.robottelo
                    sh_venv([
                        venv: "${env.WORKSPACE}/venv",
                        script:"""
                            export PYCURL_SSL_LIBRARY=\$(curl -V | sed -n 's/.*\\(NSS\\|OpenSSL\\).*/\\L\\1/p')
                            pip install -r requirements.txt
                            """
                    ])
                }
            }
        }
        stage('Create testimony.json file') {
            steps {
                dir("robottelo") {
                    sh_venv([
                        venv: "${env.WORKSPACE}/venv",
                        script:"""
                            testimony -c testimony.yaml --json print tests/foreman/ > ../testimony.json
                            """
                    ])
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts(artifacts: "**/component-owners-map.yaml, **/testimony.json")
        }
        failure {
            send_automation_email "failure"
        }
        fixed {
            send_automation_email "fixed"
        }
    }
}

def com_cmd(String mojo_user, String mojo_password, String command) {
    script {
        force = ''
        if (params.IGNORE_CACHE) {
            force = '--force'
        }
        cmd = """
        ./component-owners-manager
            --user '${mojo_user}'
            --password '${mojo_password}'
            --doc '${params.MOJO_DOC_ID}'
            ${force}
            ${command}
        """
        out = cmd.split('\n').join(' ')
        return out
    }
}
