@Library("github.com/SatelliteQE/robottelo-ci") _

pipeline {
    agent { label 'sat6-rhel' }
    environment {
        DISTRO = "rhel7"
        ANSIBLE_HOST_KEY_CHECKING = False
    }
    stages {
        stage('Clean Workspace') {
            steps {
                deleteDir()
            }
        }
        stage('Source Environment') {
           steps {
               git defaults.testfm
               make_venv python: defaults.python
               configFileProvider(
                    [configFile(fileId: 'bc5f0cbc-616f-46de-bdfe-2e024e84fcbf', variable: 'CONFIG_FILES')]) {
                    sh_venv '''
                        set -o nounset
                        source ${CONFIG_FILES}
                    '''
                    load('config/sat6_repos_urls.groovy')
                    load('config/nailgun_reviewer.groovy')
                    load('config/subscription_config.groovy')
               }
           }
        }
        stage('Build') {
            steps {
               sh_venv '''
                    pip install -U -r requirements.txt
                    cp testfm.properties.sample testfm.properties
                    cp testfm/inventory.sample testfm/inventory
                    sed -i "s/<server_hostname>/${SERVER_HOSTNAME}/g" testfm/inventory
               '''
               script {
                   def DATA="${env.ghprbCommentBody}"
                   def pattern='ok to test :'
                   DATA=DATA.replace(pattern,'')
                   echo DATA
                   if (DATA=='ok to test') {
                       PYTEST_OPTIONS='tests/'
                   } else {
                       PYTEST_OPTIONS=DATA
                   }
                   propargs = [
                       'RHN_USERNAME' : RHN_USERNAME,
                       'RHN_PASSWORD' : env.RHN_PASSWORD,
                       'RHN_POOLID' : RHN_POOLID,
                       'DOGFOOD_ORG' : DOGFOOD_ORG,
                       'DOGFOOD_ACTIVATIONKEY' : env.DOGFOOD_ACTIVATIONKEY,
                       'DOGFOOD_URL' : DOGFOOD_URL,
                       'HOTFIX_URL' : env.HOTFIX_URL
                   ]
                   parse_ini ini_file: "${WORKSPACE}//testfm.properties", properties: propargs
               }
            }
        }
        stage('Run Tests') {
            steps {
                def command = 'pytest -sv --junit-xml=foreman-results.xml --ansible-host-pattern satellite --ansible-user root --ansible-inventory testfm/inventory '
                try {
                    sh_venv command + '${PYTEST_OPTIONS}'
                }
                catch(all) {
                    currentBuild.result = 'UNSTABLE'
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
