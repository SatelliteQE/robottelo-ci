node('sat6-rhel7')  {
    stage('Setup workspace') {
        setup_workspace()
    }

    stage('Score Bugs') {
        withCredentials([usernamePassword(credentialsId: 'SAT_TEAM_TEIID',
                     usernameVariable: 'TEIID_USERNAME', passwordVariable: 'TEIID_PASSWORD'),
                     string(credentialsId: 'PM_SAT_API_KEY', variable: 'API_KEY')]) {

          virtEnv3('./ci', "cd scripts && ./bug_scoring.py --bz_username pm-sat@redhat.com --bz_api_key '${env.API_KEY}' --teiid_username '${env.TEIID_USERNAME}' --teiid_password '${env.TEIID_PASSWORD}' --teiid_host virtualdb.engineering.redhat.com --product 'Red Hat Satellite'")
        }
    }

    stage('Teardown') {
      notify("PM Score run has completed")
    }
}

