#!/usr/bin/groovy
node('sat6-rhel7') {
    stage("Setup Workspace") {

        deleteDir()
        setupAnsibleEnvironment {
            git_remote = 'JacobCallahan'
            git_repo = 'content-host-d'
        }
    }

    stage("Setup Content Host Environment.") {

        // Work around for parameters not being accessible in functions
        writeFile file: 'container_os', text: CONTAINER_OS
        def container_os = readFile 'container_os'
        writeFile file: 'container_host', text: CONTAINER_HOST
        def container_host = readFile 'container_host'
        writeFile file: 'startup_file', text: CUSTOM_CONTAINER_STARTUP_FILE
        def startup_file = readFile 'startup_file'
        writeFile file: 'setup_container_host', text: SETUP_CONTAINER_HOST
        def setup_container_host = readFile 'setup_container_host'

        def rhn_username = env.RHN_USERNAME
        def rhn_password = env.RHN_PASSWORD
        def rhn_poolid = env.RHN_POOLID

        def workspace = pwd()

        if (setup_container_host) {

            runPlaybook {
                playbook = 'chd-setup.yaml'
                ansibledir = 'playbooks'
                inventoryContent = container_host
                extraVars = [
                    'CUSTOM_CONTAINER_STARTUP_FILE': startup_file,
                    'CONTAINER_OS': container_os,
                    'RHN_USERNAME': rhn_username,
                    'RHN_PASSWORD': rhn_password,
                    'RHN_POOLID': rhn_poolid,
                    'WORKSPACE': workspace
                ]
            }
        }
    }

    stage("Run Satellite6 Mass Content Host Registration.") {

        writeFile file: 'container_os', text: CONTAINER_OS
        def container_os = readFile 'container_os'
        writeFile file: 'satellite_host', text: SATELLITE_HOST
        def satellite_host = readFile 'satellite_host'
        writeFile file: 'content_host_prefix', text: CONTENT_HOST_PREFIX
        def content_host_prefix = readFile 'content_host_prefix'
        writeFile file: 'activation_key', text: ACTIVATION_KEY
        def activation_key = readFile 'activation_key'
        writeFile file: 'number_of_hosts', text: NUMBER_OF_HOSTS
        def number_of_hosts = readFile 'number_of_hosts'
        writeFile file: 'container_limit', text: LIMIT
        def container_limit = readFile 'container_limit'
        writeFile file: 'exit_criteria', text: EXIT_CRITERIA
        def exit_criteria = readFile 'exit_criteria'
        writeFile file: 'container_host', text: CONTAINER_HOST
        def container_host = readFile 'container_host'

        def container_tag = container_os.toLowerCase()


        runPlaybook {
            playbook = 'chd-run.yaml'
            inventoryContent = container_host
            ansibledir = 'playbooks'
            extraVars = [
                'SATELLITE_HOST': satellite_host,
                'CONTENT_HOST_PREFIX': content_host_prefix,
                'ACTIVATION_KEY': activation_key,
                'NUMBER_OF_HOSTS': number_of_hosts,
                'LIMIT': container_limit,
                'EXIT_CRITERIA': exit_criteria,
                'CONTAINER_TAG': container_tag
            ]
        }
    }
}
