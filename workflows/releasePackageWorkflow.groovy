import groovy.json.JsonSlurper

def branch_map = [
    'SATELLITE-6.2.0': [
        'repo': 'Satellite 6.2 Source Files',
        'version': '6.2.0'
    ],
    'SATELLITE-6.3.0': [
        'repo': 'Satellite 6.3 Source Files',
        'version': '6.3.0'
    ]
]
def release_branch = env.releaseBranch
def repo_name = gitRepository.split('/')[1]
def version_map = branch_map[release_branch]

node('rhel') {

    snapperStage("Setup Environment") {


        dir(repo_name) {
            withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'jenkins-gitlab', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME']]) {

                git url: "https://${env.USERNAME}:${env.PASSWORD}@${env.GIT_HOSTNAME}/${gitRepository}.git", branch: release_branch

            }
        }

        dir('tool_belt') {
            git url: "https://${env.GIT_HOSTNAME}/satellite6/tool_belt.git", branch: 'master'
            sh 'bundle install --without=development'
        }

        setupAnsibleEnvironment {}
    }

    snapperStage("Identify Bugs") {

        def releaseTag = ''

        dir(repo_name) {
            sh "../tool_belt/tools.rb release find-bz-ids --output-file bz_ids.json"
            archive 'bz_ids.json'
        }
    }


    snapperStage("Move Bugs to Modified") {

        dir(repo_name) {
            def ids = []
            def bzs = readFile 'bz_ids.json'
            bzs = new JsonSlurper().parseText(bzs)

            for (bz in bzs) {
                ids << bz['id']
            }

            if (ids.size() > 0) {
                ids = ids.join(' --bug ')

                withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'bugzilla-credentials', passwordVariable: 'BZ_PASSWORD', usernameVariable: 'BZ_USERNAME']]) {

                    sh "../tool_belt/tools.rb bugzilla move-to-modified --username ${env.BZ_USERNAME} --password ${env.BZ_PASSWORD} --bug ${ids} --version ${version_map['version']}"

                }
            }
        }
    }

    snapperStage("Set External Tracker for Commit") {

        dir(repo_name) {
            def commits = readFile 'bz_ids.json'
            commits = new JsonSlurper().parseText(commits)

            for (i = 0; i < commits.size(); i += 1) {
                def commit = commits[i]
                def hash = (gitRepository + '/commit/' + commit['commit']).toString()
                def id = commit['id'].toString()

                withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'bugzilla-credentials', passwordVariable: 'BZ_PASSWORD', usernameVariable: 'BZ_USERNAME']]) {

                    sh "../tool_belt/tools.rb bugzilla set-gitlab-tracker --username ${env.BZ_USERNAME} --password ${env.BZ_PASSWORD} --external-tracker \"${hash}\" --bug ${id} --version ${version_map['version']}"

                }
            }
        }

    }

    snapperStage("Bump Version") {

        withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'jenkins-gitlab', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME']]) {

            dir(repo_name) {
                sh "git config user.email 'sat6-jenkins@redhat.com'"
                sh "git config user.name 'Jenkins'"

                sh "../tool_belt/tools.rb release bump-version --output-file version.json"
                archive "version.json"
                releaseTag = readFile 'version.json'

                sh "git push origin ${release_branch}"
                sh "git push origin ${releaseTag}"
            }

        }
    }


    snapperStage("Build Source") {

        def artifact = ''
        def artifact_path = ''

        dir(repo_name) {
            sh "../tool_belt/tools.rb release build-source --type ${sourceType} --output-file artifact"
            artifact = readFile 'artifact'

            artifact = readFile('artifact').replace('"', '')
            artifact_path = sh(returnStdout: true, script: 'pwd').trim()
            artifact_path = artifact_path + '/' + artifact
        }
        runPlaybook {
            playbook = 'playbooks/upload_package.yml'
            extraVars = [
                'file': artifact_path,
                'repo': version_map['repo'],
                'product': 'Source Files',
                'organization': 'Sat6-CI'
            ]
        }

        sh "rm ${artifact_path}"
    }

}
