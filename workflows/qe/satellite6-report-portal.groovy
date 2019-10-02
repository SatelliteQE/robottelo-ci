@Library("github.com/SatelliteQE/robottelo-ci") _

pipeline {
    agent {
        label 'sat6-rhel'
    }
    stages {
        stage('Virtualenv') {
            steps {
                make_venv python: defaults.python
            }
        }
        stage('Clone rp_tools repo') {
            steps {
            configFileProvider(
            [configFile(fileId: 'e8b0ed3c-2ca3-4a0c-a922-60264c11bbc9', variable: 'RP_TOOLS')]) {
                sh_venv """
                source \${RP_TOOLS}
                """
                }
            }
        }
        stage('Obtain component-owners-map.yaml and testimony.json') {
            steps {
                copyArtifacts(projectName: 'satellite6-component-owners',
                    selector: 'lastSuccessful',
                    target: 'rp_tools/scripts/reportportal_cli/'
                )
            }
        }
        stage('Configure rp_tools') {
            steps {
                sh_venv """
                    cd rp_tools
                    export PYCURL_SSL_LIBRARY=\$(curl -V | sed -n 's/.*\\(NSS\\|OpenSSL\\).*/\\L\\1/p')
                    pip install -r requirements.txt
                    """
                configFileProvider(
                    [configFile(fileId: 'bc5f0cbc-616f-46de-bdfe-2e024e84fcbf', variable: 'CONFIG_FILES')]) {
                        sh_venv '''
                            source ${CONFIG_FILES}
                            cp config/rp_conf.yaml rp_tools/scripts/reportportal_cli/rp_conf.yaml
                            sed -i "s/^rp_project.\\+$/rp_project: ${RP_PROJECT}/" rp_tools/scripts/reportportal_cli/rp_conf.yaml
                            mkdir rp_tools/scripts/jenkins_junit/junits
                        '''
                    }
            }
        }
        stage('Collect Junit XMLs') {
            steps {
                sh_venv '''
                    cd rp_tools/scripts/jenkins_junit/
                    if echo "${AUTOMATION_BUILD_URL}" | grep -q 'automation-upgraded-[0-9.]\\+-all-tiers-rhel[0-9]\\+'; then
                        cd junits/ && rm -f *.xml
                        wget --no-verbose --no-check-certificate "${AUTOMATION_BUILD_URL}/artifact/all-tiers-upgrade-parallel-results.xml"
                        wget --no-verbose --no-check-certificate "${AUTOMATION_BUILD_URL}/artifact/all-tiers-upgrade-sequential-results.xml"
                    else
                        python3 fetch_junit.py ${AUTOMATION_BUILD_URL} -v
                    fi
                '''
            }
        }
        stage('Push results to Report Portal') {
            steps {
                sh_venv '''
                    cd rp_tools/scripts/reportportal_cli
                    if echo "${AUTOMATION_BUILD_URL}" | grep -q 'automation-upgraded-[0-9.]\\+-all-tiers-rhel[0-9]\\+'; then
                        rp_cli_extra_opts="--launch_name Upgrades"
                    fi
                    ./rp_cli.py --xunit_feed '../jenkins_junit/junits/*.xml' --strategy Sat --config rp_conf.yaml --launch_tags "${BUILD_TAGS}" ${rp_cli_extra_opts}
                '''
            }
        }
        stage('Claim known issues') {
            steps {
                sh_venv '''
                    cd rp_tools/scripts/reportportal_cli/
                    master=$( echo "$BUILD_TAGS" | sed 's/ \\+/\\n/g' | grep '^6\\.[0-9]\\+$' | head -n 1 )
                    rules="kb$( echo "$master" | sed 's/\\.//' ).json"
                    if [ -e "$rules" ]; then
                        echo "Looks like we are processing '$master' launch, so will use '$rules' rules file"
                        ./claiming_cli.py --insecure --rules "$rules" -n 8
                    else
                        echo "ERROR: No rules file for launch with tags: '$BUILD_TAGS'" >&2
                    fi
                '''
            }
        }
        stage('E-Mail owners') {
            when {
                    expression { !env.AUTOMATION_BUILD_URL.contains('upstream-nightly') }
            }
            steps {
                sh_venv '''
                    cd rp_tools/scripts/reportportal_cli/
                    #to prevent this step from actually sending the mail (dry run) just uncomment this:
                    #sed -i 's/server\\.sendmail/print/' alert_cli.py
                    ./alert_cli.py
                '''
            }
        }
        stage('Generate initial status report') {
            steps {
                sh_venv '''
                    cd rp_tools/scripts/reportportal_cli/
                    ./todo_cli.py
                '''
            }
        }

    }
  }
