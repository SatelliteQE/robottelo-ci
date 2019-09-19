@Library("github.com/SatelliteQE/robottelo-ci") _

pipeline {
    agent { label 'sat6-rhel' }
    environment {
        OS_VERSION = "7"
        SATELLITE_VERSION="6.6"
    }
    stages {
        stage('Clean Workspace') {
            steps {
                deleteDir()
            }
        }
        stage('Source Environment') {
           steps {
               git defaults.robottelo
               make_venv python: defaults.python
               configFileProvider(
                    [configFile(fileId: 'bc5f0cbc-616f-46de-bdfe-2e024e84fcbf', variable: 'CONFIG_FILES')]) {
                    sh_venv '''
                        set -o nounset
                        source ${CONFIG_FILES}
                    '''
                    load('config/sat6_repos_urls.groovy')
                    load('config/nailgun_reviewer.groovy')
               }
           }
        }
        stage('Build') {
            steps {
               sh_venv '''
                    cp config/robottelo.properties ./robottelo.properties
                    sed -i "s|@stable-satellite#egg=nailgun|@refs/pull/${ghprbPullId}/head|g" requirements.txt
                    export PYCURL_SSL_LIBRARY=\$(curl -V | sed -n 's/.*\\(NSS\\|OpenSSL\\).*/\\L\\1/p')
                    pip install -r requirements.txt docker-py pytest-xdist==1.25.0 sauceclient
               '''
               script {
                   def DATA="${env.ghprbCommentBody}"
                   def pattern='ok to test :'
                   DATA=DATA.replace(pattern,'')
                   echo DATA
                   if (DATA=='ok to test') {
                       PYTEST_OPTIONS='tests/foreman/api/'
                   } else {
                       PYTEST_OPTIONS=DATA
                   }
                   all_args = [
                   'hostname': SERVER_HOSTNAME,
                   'ssh_username': SSH_USER,
                   'admin_username': FOREMAN_ADMIN_USER,
                   'admin_password': FOREMAN_ADMIN_PASSWORD,
                   'bz_password': env.BUGZILLA_PASSWORD,
                   'bz_username': env.BUGZILLA_USER,
                   'sattools_repo': "rhel8=${env.RHEL8_TOOLS_REPO},rhel7=${env.RHEL7_TOOLS_REPO},rhel6=${env.RHEL6_TOOLS_REPO}",
                   'capsule_repo': CAPSULE_REPO]
                   parse_ini ini_file: "${WORKSPACE}//robottelo.properties" , properties: all_args
                   }
            }
        }
        stage('Run Tests') {
            steps {
            sh_venv '''
            set +e
            pytest() {
                $(which py.test) -v --junit-xml=foreman-results.xml -o junit_suite_name=standalone-automation -m "''' + PYTEST_MARKS + '''" "$@"
            }
            pytest ''' + PYTEST_OPTIONS + '''
            set -e
            '''
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
