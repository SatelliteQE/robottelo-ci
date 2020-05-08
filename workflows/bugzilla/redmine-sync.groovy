node('sat6-rhel7')  {
    stage('Setup workspace') {
        setup_workspace()
    }

    stage('Sync Bugs') {
        withCredentials([string(credentialsId: 'PM_SAT_API_KEY', variable: 'BZ_API_KEY'),
                     string(credentialsId: 'PM_SAT_REDMINE_KEY', variable: 'REDMINE_API_KEY')]) {

          virtEnv3('./ci', "cd scripts && ./redmine_sync.py --bz_username pm-sat@redhat.com --bz_api_key '${env.BZ_API_KEY}' --redmine_key '${env.REDMINE_API_KEY}' sync" )
        }
    }

    stage('Teardown') {
      notify("Redmine sync run has completed")
    }
}

