@Library("github.com/SatelliteQE/robottelo-ci") _

def instance_id
def floating_ip
def inventory

pipeline {
    agent {
        label 'sat6-rhel'
    }
    environment {
        OS = credentials('osp_creds')
        OS_USERNAME = "${OS_USR}"
        OS_PASSWORD = "${OS_PSW}"
        OS_AUTH_URL = "${FM_AUTH_URL}"
        OS_TENANT_NAME = "${FM_TENANT_NAME}"
        OS_USER_DOMAIN_NAME = "${FM_USER_DOMAIN_NAME}"
        OS_PROJECT_DOMAIN_ID = "${FM_PROJECT_DOMAIN_ID}"
    }
    stages {
        stage('Virtualenv') {
  	        steps {
                make_venv python: defaults.python
            }
        }
        stage('Pip install') {
            steps {
            configFileProvider(
		      [configFile(fileId: 'bc5f0cbc-616f-46de-bdfe-2e024e84fcbf', variable: 'CONFIGS')]) {
	    	    sh_venv '''
	    	      source ${CONFIGS}
	    	      source config/subscription_config.conf
	    	      source config/5minute.conf
	    	      export SAT_RELEASE=\${SNAP_VERSION%-*}
	    	      export SAT_SNAP=\${SNAP_VERSION#*-}
		      pip install python-openstackclient ansible
                '''
              }
            }
        }
        stage('Boot up temp VM') {
            steps {
                script {
                    instance_id = sh_venv returnStdout: true, script: '''
                        #. .env/bin/activate
                        nova boot --flavor ${FM_FLAVOR} --image ${FM_IMAGE_NAME} --nic net-id=${FM_NET_ID} --key-name ${FM_KEY_NAME} ${FM_INSTANCE_NAME} | tee > instance_info
                        grep "^|\\sid" instance_info | cut -d '|' -f 3 | xargs
                        '''
                }
                withEnv(["INSTANCE_ID=${instance_id}"]) {
                    retry(20) {
                        sh_venv label: 'wait for Instance to become ACTIVE', script:'''
                            export STATUS_CMD="nova show ${INSTANCE_ID} | grep status | cut -d '|' -f 3 | xargs"
                            STATUS=$(eval ${STATUS_CMD})
                            [ ${STATUS}  == "ACTIVE" ]
                        '''
                        sleep(6)
                    }
                }
            }
        }
        stage('Set floating IP') {
            steps {
                withEnv(["INSTANCE_ID=${instance_id}"]) {
                    script {
                        floating_ip = sh_venv label: 'Get Floating IP', returnStdout: true, script: '''
                            openstack floating ip create ${FM_FLOATING_IP_POOL_NAME} | tee > floating_ip
                            echo -n $(grep floating_ip_address floating_ip | cut -d '|' -f 3 | xargs)
                            '''
                    }
                    withEnv(["FLOATING_IP=${floating_ip}"]) {
                        sh_venv '''
                        openstack server add floating ip ${INSTANCE_ID} ${FLOATING_IP}
                        '''
                        sleep(30)
                    }
                }
            }
        }
        stage('Install Satellite') {
            steps {
                withEnv(["INSTANCE_ID=${instance_id}", "FLOATING_IP=${floating_ip}"]) {
                    script {
                        inventory = sh_venv label: 'setup Ansible inventory', returnStdout: true, script:'''
                            export TMP_INV=$(mktemp -p ./ inventory-XXX)
                            echo ${FM_CUST_OS_DN} | sed "s/{ip}/${FLOATING_IP//./-}/" > ${TMP_INV}
                            echo ${TMP_INV}
                        '''
                    }
                    ansiblePlaybook become: true,
                      colorized: true,
                      credentialsId: '4d69f992-894a-457e-802c-fde131f4abb8',
                      disableHostKeyChecking: true,
                      installation: 'ansible',
                      inventory: "${inventory}",
                      playbook: 'ansible/playbooks/create_5minute_image.yml',
                      extraVars: [
                        'dogfood': "${env.DOGFOOD_URL}",
                        'dogfood_org': "${env.DOGFOOD_ORG}",
                        'satellite_release': "${env.SAT_VERSION}".split('-')[0],
                        'rhel_version': "${env.RHEL_VERSION}",
                      ]
                }
            }
        }
        stage('Create image from temp VM') {
            steps {
                withEnv(["INSTANCE_ID=${instance_id}", "FLOATING_IP=${floating_ip}"]) {
		    sh_venv label: 'Shut off the instance', script: '''
		        nova stop ${INSTANCE_ID}
		    '''
                    retry(20) {
                        sh_venv label: 'wait for Instance to become SHUTOFF', script: '''
                            export STATUS_CMD="nova show ${INSTANCE_ID} | grep status | cut -d '|' -f 3 | xargs"
			    STATUS=$(eval ${STATUS_CMD})
                            [ ${STATUS} == "SHUTOFF" ]
                        '''
                        sleep(6)
                    }
                    sh_venv label: 'create the image', script: '''
                        nova image-create --metadata contact=${FM_CONTACT} --metadata default_flavor=${FM_FLAVOR} --metadata cscripts=${FM_CSCRIPTS} --poll ${INSTANCE_ID} ${FM_IMAGE_NAME}-${SAT_VERSION}
                        '''
                }
            }
        }
    }
    post {
        always {
            withEnv(["INSTANCE_ID=${instance_id}", "FLOATING_IP=${floating_ip}"]) {
                    sh_venv label: 'delete the floating IP and remove instance', script: '''
                        openstack floating ip delete ${FLOATING_IP}
                        nova delete ${INSTANCE_ID}
                    '''
            }
        }
    }
}
