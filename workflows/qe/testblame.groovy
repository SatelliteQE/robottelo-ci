@Library("github.com/SatelliteQE/robottelo-ci") _

pipeline {
    agent {
        label 'sat6-rhel'
    }
    stages {
        stage('setup config files') {
            steps {
                configFileProvider(
                [configFile(fileId: 'bc5f0cbc-616f-46de-bdfe-2e024e84fcbf', variable: 'CONFIG_FILES')]) {
                    sh_venv 'source ${CONFIG_FILES}'
                }
            }
        }
        stage('Install Testblame'){
            steps{
                make_venv python: defaults.python
                git defaults.testblame
                sh_venv '''pip install -r requirements.txt
                pip install --editable .
                '''
                
            }
        }
        stage('Setup Plotly'){
            steps{
                initialize()
                sh_venv '''
                python -c "import chart_studio;chart_studio.tools.set_credentials_file(username='testblame', api_key=\'''' + API_KEY + '''\')" 
                '''
            }
        }
        stage('Download the testblame database file'){
            steps{
                    withCredentials([sshUserPrivateKey(credentialsId: 'id_hudson_rsa', keyFileVariable: 'identity', 
                    passphraseVariable: '', usernameVariable: 'userName')]) {
                        script{
                            remote = [host: REMOTE_SERVER , user: userName, name: 'database_server', allowAnyHosts: true, identityFile: identity]
                            echo "Taking backup for database.."
                            sshCommand remote: remote, command: 'cp /tmp/database.sqlite3 /tmp/database.sqlite3.bk_$(date +"%Y%m%d_%H%M%S")'
                            echo "Cleaning old backups .."
                            sshCommand remote: remote, command: '''find /tmp/ -name "*.sqlite3.bk*" -type f -mtime +30 -exec rm -f {} \\;'''
                            sshGet remote: remote, from: '/tmp/database.sqlite3', into: '.', override: true
                        }
                }
            }
        }
        stage('Configure Testblame'){
            steps{
                script{
                    if (!JENKINS_JOB_URL?.trim()) {
                        // fetching and building jenkins url from jenkins config file

                        JENKINS_JOB_URL = BUILD_JENKINS_JOB_URL
                        JENKINS_JOB_URL = modified_jenkins_url(JENKINS_JOB_URL, SATELLITE_VERSION)
                    }
                    if (!TO_EMAIL?.trim()) {
                        TO_EMAIL = BUILD_TO_EMAIL
                    }
                    if (!FROM_EMAIL?.trim()) {
                        FROM_EMAIL = BUILD_FROM_EMAIL
                    }
                    sh_venv '''
                        testblame set-config --git-url=${GIT_REPO_URL} --jenkins-url '''+ JENKINS_JOB_URL +''' --version "${SATELLITE_VERSION}"
                        testblame send-email-report --from_email='''+ FROM_EMAIL +''' --to_email='''+ TO_EMAIL +''' --subject="Test automation analysis for Sat ${SATELLITE_VERSION}" --with-link=yes --with-graph=yes --component=robottelo_component.json
                    '''
                }
            }
        }
        stage('Upload the testblame database file'){
            steps{
                    withCredentials([sshUserPrivateKey(credentialsId: 'id_hudson_rsa', keyFileVariable: 'identity', 
                    passphraseVariable: '', usernameVariable: 'userName')]) {
                        script{
                            remote = [host: REMOTE_SERVER , user: userName, name: 'database_server', allowAnyHosts: true, identityFile: identity]
                            echo "Uploading database file into Database Server.."
                            sshPut remote: remote, from: 'database.sqlite3', into: '/tmp/', override: true
                    }
                }
            }
        }
    }
}

def initialize() {
    load('config/testblame.groovy')
    env.SMTP_SERVER_NAME=SMTP_SERVER_NAME
    env.SMTP_SERVER_PORT=SMTP_SERVER_PORT
}

def modified_jenkins_url(JENKINS_JOB_URL, SATELLITE_VERSION){
    def os_version = SATELLITE_VERSION =~ /rhel.+/
    def satellite_version = SATELLITE_VERSION =~ /^\d\.\d/
    JENKINS_JOB_URL = JENKINS_JOB_URL.replaceAll('<os>', os_version[0])
    JENKINS_JOB_URL = JENKINS_JOB_URL.replaceAll('<satellite_version>', satellite_version[0])

    return JENKINS_JOB_URL
}
