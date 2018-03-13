def branch_map = [
    'SATELLITE-6.2.0': [
        'repo': 'Satellite 6.2 Source Files',
        'version': '6.2.0',
        'tool_belt_config': './configs/satellite/',
        'foreman_branch': '1.11-stable',
        'packaging_job': null
    ],
    'SATELLITE-6.3.0': [
        'repo': 'Satellite 6.3 Source Files',
        'version': '6.3.0',
        'tool_belt_config': './configs/satellite/',
        'foreman_branch': '1.15-stable',
        'packaging_job': 'sat-63-satellite-packaging-update'
    ],
    'SATELLITE-6.4.0': [
        'repo': 'Satellite 6.4 Source Files',
        'version': '6.4.0',
        'tool_belt_config': './configs/satellite/',
        'foreman_branch': '1.17-stable',
        'packaging_job': 'sat-64-satellite-packaging-update'
    ],
    'RHUI-3.0.0': [
        'repo': 'RHUI 3.0 Source Files',
        'version': '3.0.0',
        'tool_belt_config': './configs/rhui/',
        'packaging_job': 'rhui-3-rhui-packaging-update'
    ]
]
def release_branch = env.releaseBranch
def repo_name = gitRepository.split('/')[1]
def version_map = branch_map[release_branch]
def tool_belt_config = version_map['tool_belt_config']
def packaging_job = version_map['packaging_job']
def releaseTag = ''

node('rvm') {

    stage("Setup Environment") {

        deleteDir()

        setupAnsibleEnvironment {}

        dir(repo_name) {
            withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'jenkins-gitlab', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME']]) {

                checkout([
                    $class: 'GitSCM',
                    branches: [[name: release_branch]],
                    userRemoteConfigs: [[url: "https://${env.USERNAME}:${env.PASSWORD}@${env.GIT_HOSTNAME}/${gitRepository}.git"]],
                    extensions: [
                        [$class: 'CloneOption', depth: 0, noTags: false, reference: '', shallow: false, timeout: 20],
                        [$class: 'LocalBranch']
                    ],
                ])

            }
        }

        dir('tool_belt') {
            setup_toolbelt()
        }
    }

    stage("Identify Bugs") {

        dir('tool_belt') {
            toolBelt {
                command = 'release find-bz-ids'
                config = tool_belt_config
                options = [
                    "--dir ../${repo_name}",
                    "--output-file bz_ids.json"
                ]
            }
            archive 'bz_ids.json'
        }
    }


    stage("Move Bugs to Modified") {

        dir('tool_belt') {
            def ids = []
            def bzs = readJSON(file: 'bz_ids.json')

            for (bz in bzs) {
                ids << bz['id']
            }

            if (ids.size() > 0) {
                ids = ids.join(' --bug ')

                withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'bugzilla-credentials', passwordVariable: 'BZ_PASSWORD', usernameVariable: 'BZ_USERNAME']]) {

                    toolBelt {
                        command = 'bugzilla set-cherry-picked'
                        config = tool_belt_config
                        options = [
                            "--bz-username ${env.BZ_USERNAME}",
                            "--bz-password ${env.BZ_PASSWORD}",
                            "--bug ${ids}",
                            "--version ${version_map['version']}"
                        ]
                    }

                }

            }
        }
    }

    stage("Set External Tracker for Commit") {

        dir('tool_belt') {
            def commits = readJSON(file: 'bz_ids.json')

            for (i = 0; i < commits.size(); i += 1) {
                def commit = commits[i]
                def hash = (gitRepository + '/commit/' + commit['commit']).toString()
                def id = commit['id'].toString()

                withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'bugzilla-credentials', passwordVariable: 'BZ_PASSWORD', usernameVariable: 'BZ_USERNAME']]) {

                    toolBelt {
                        command = 'bugzilla set-gitlab-tracker'
                        config = tool_belt_config
                        options = [
                            "--bz-username ${env.BZ_USERNAME}",
                            "--bz-password ${env.BZ_PASSWORD}",
                            "--external-tracker \"${hash}\"",
                            "--bug ${id}",
                            "--version ${version_map['version']}"
                        ]
                    }

                }
            }
        }

    }

    stage("Bump Version") {

        withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'jenkins-gitlab', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME']]) {

            dir(repo_name) {

                sh "git config user.email 'sat6-jenkins@redhat.com'"
                sh "git config user.name 'Jenkins'"

                dir('../tool_belt') {
                    toolBelt {
                        command = 'release bump-version'
                        config = tool_belt_config
                        options = [
                            "--dir ../${repo_name}",
                            "--output-file version"
                        ]
                    }
                    archive "version"
                    releaseTag = readFile 'version'
                }

                sh "git push origin ${release_branch}"
                sh "git push origin ${releaseTag}"
            }

        }
    }


    stage("Build Source") {

        if (repo_name in ['katello-installer', 'foreman-installer']) {
            dir(repo_name) {
                try {

                    withRVM(['gem install bundler'])
                    withRVM(['bundle install'])
                    withRVM(["FOREMAN_BRANCH=${version_map['foreman_branch']} rake pkg:generate_source"])

                    sh 'ls pkg/*.tar.* > ../tool_belt/artifact'

                } finally {

                    cleanup_rvm()

                }
            }
        } else {

            dir('tool_belt') {
                toolBelt(
                    command: 'release build-source',
                    config: tool_belt_config,
                    options: [
                        "--dir ../${repo_name}",
                        "--type ${sourceType}",
                        "--output-file artifact"
                    ]
                )
            }

        }

    }

    stage("Upload Source") {

        def artifact = ''
        def artifact_path = ''

        dir('tool_belt') {
            artifact = readFile('artifact').replace('"', '').trim()
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

    stage("Mark BZs as needs_rpm") {

        dir('tool_belt') {
            def ids = []
            def bzs = readJSON(file: 'bz_ids.json')

            for (bz in bzs) {
                ids << bz['id']
            }

            if (ids.size() > 0) {
                ids = ids.join(' --bug ')

                withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'bugzilla-credentials', passwordVariable: 'BZ_PASSWORD', usernameVariable: 'BZ_USERNAME']]) {

                    toolBelt(
                        command: 'release set-build-state',
                        config: tool_belt_config,
                        options: [
                            "--bz-username ${env.BZ_USERNAME}",
                            "--bz-password ${env.BZ_PASSWORD}",
                            "--state needs_rpm",
                            "--bug ${ids}",
                            "--version ${version_map['version']}"
                        ]
                    )

                }

            }
        }

    }

    stage("Trigger packaging update") {
        if (packaging_job) {
          build job: packaging_job, parameters: [
            [$class: 'StringParameterValue', name: 'project', value: repo_name],
            [$class: 'StringParameterValue', name: 'version', value: releaseTag],
            [$class: 'StringParameterValue', name: 'targetBranch', value: release_branch],
          ]
        }
    }
}
