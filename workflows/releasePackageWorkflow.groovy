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

        deleteDir()

        setupAnsibleEnvironment {}

        dir(repo_name) {
            withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'jenkins-gitlab', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME']]) {

                git url: "https://${env.USERNAME}:${env.PASSWORD}@${env.GIT_HOSTNAME}/${gitRepository}.git", branch: release_branch

            }
        }

        dir('tool_belt') {
            git url: "https://${env.GIT_HOSTNAME}/satellite6/tool_belt.git", branch: 'master'
            sh 'bundle install --without=development'
        }
    }

    snapperStage("Identify Bugs") {

        def releaseTag = ''

        dir('tool_belt') {
            sh "bundle exec ./tools.rb release find-bz-ids --dir ../${repo_name} --output-file bz_ids.json"
            archive 'bz_ids.json'
        }
    }


    snapperStage("Move Bugs to Modified") {

        dir('tool_belt') {
            def ids = []
            def bzs = readFile 'bz_ids.json'
            bzs = new JsonSlurper().parseText(bzs)

            for (bz in bzs) {
                ids << bz['id']
            }

            if (ids.size() > 0) {
                ids = ids.join(' --bug ')

                withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'bugzilla-credentials', passwordVariable: 'BZ_PASSWORD', usernameVariable: 'BZ_USERNAME']]) {

                    sh "bundle exec ./tools.rb bugzilla move-to-modified --username ${env.BZ_USERNAME} --password ${env.BZ_PASSWORD} --bug ${ids} --version ${version_map['version']}"

                }

            }
        }
    }

    snapperStage("Set External Tracker for Commit") {

        dir('tool_belt') {
            def commits = readFile 'bz_ids.json'
            commits = new JsonSlurper().parseText(commits)

            for (i = 0; i < commits.size(); i += 1) {
                def commit = commits[i]
                def hash = (gitRepository + '/commit/' + commit['commit']).toString()
                def id = commit['id'].toString()

                withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'bugzilla-credentials', passwordVariable: 'BZ_PASSWORD', usernameVariable: 'BZ_USERNAME']]) {

                        sh "bundle exec ./tools.rb bugzilla set-gitlab-tracker --username ${env.BZ_USERNAME} --password ${env.BZ_PASSWORD} --external-tracker \"${hash}\" --bug ${id} --version ${version_map['version']}"

                }
            }
        }

    }

    snapperStage("Bump Version") {

        withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'jenkins-gitlab', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME']]) {

            dir(repo_name) {
                def releaseTag = ''

                sh "git config user.email 'sat6-jenkins@redhat.com'"
                sh "git config user.name 'Jenkins'"

                dir('../tool_belt') {
                    sh "bundle exec ./tools.rb release bump-version --dir ../${repo_name} --output-file version.json"
                    archive "version.json"
                    releaseTag = readFile 'version.json'
                }

                sh "git push origin ${release_branch}"
                sh "git push origin ${releaseTag}"
            }

        }
    }


    snapperStage("Build Source") {

        dir('tool_belt') {
            sh "bundle exec ./tools.rb release build-source --dir ../${repo_name} --type ${sourceType} --output-file artifact"
        }

    }

    snapperStage("Upload Source") {

        def artifact = ''
        def artifact_path = ''

        dir('tool_belt') {
            artifact = readFile('artifact').replace('"', '')
        }

        dir(repo_name) {
            artifact_path = sh(returnStdout: true, script: 'pwd').trim()
            artifact_path = artifact_path + '/' + artifact
        }

        runPlaybook {
            playbook = 'playbooks/upload_package.yml'
            extraVars = [
                'artifact': artifact_path,
                'repo': version_map['repo'],
                'product': 'Source Files',
                'organization': 'Sat6-CI'
            ]
        }

        dir('tool_belt') {
            sh "rm ${artifact_path}"
        }
    }

}
