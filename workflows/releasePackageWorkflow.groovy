def release_branch = env.releaseBranch
def repo_name = gitRepository.split('/')[1]
def version_map = branch_map[release_branch]
def tool_belt_config = version_map['tool_belt_config']
def packaging_job = version_map['packaging_job']
def ruby = branch_map[release_branch]['ruby']

pipeline {

    agent { label 'rvm'}

    options {
      ansiColor('xterm')
      disableConcurrentBuilds()
      timestamps()
    }

    stages {
        stage("Setup Environment") {
            steps {

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

            }
        }

        stage("Identify Bugs") {
            steps {

                toolBelt(
                    command: 'release find-bz-ids',
                    config: tool_belt_config,
                    options: [
                        "--dir ../${repo_name}",
                        "--output-file bz_ids.json"
                    ],
                    archive_file: 'bz_ids.json'
                )

            }
        }


        stage("Move Bugs to Modified") {
            steps {
                script {

                    def ids = []
                    def bzs = readJSON(file: 'tool_belt/bz_ids.json')
                    for (bz in bzs) {
                        ids << bz['id']
                    }

                    if (ids.size() > 0) {
                        ids = ids.join(' --bug ')

                        withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'bugzilla-credentials', passwordVariable: 'BZ_PASSWORD', usernameVariable: 'BZ_USERNAME']]) {

                            toolBelt(
                                command: 'bugzilla set-cherry-picked',
                                config: tool_belt_config,
                                options: [
                                    "--bz-username ${env.BZ_USERNAME}",
                                    "--bz-password ${env.BZ_PASSWORD}",
                                    "--bug ${ids}",
                                    "--version ${version_map['version']}"
                                ]
                            )
                        }
                    }

                }
            }
        }


        stage("Bump Version") {
            steps {

                withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'jenkins-gitlab', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME']]) {

                    dir(repo_name) {

                        sh "git config user.email 'sat6-jenkins@redhat.com'"
                        sh "git config user.name 'Jenkins'"

                    }

                    toolBelt(
                        command: 'release bump-version',
                        config: tool_belt_config,
                        options: [
                            "--dir ../${repo_name}",
                            "--output-file version"
                        ],
                        archive_file: 'version'
                    )

                    script {
                        releaseTag = readFile 'tool_belt/version'
                    }

                    dir(repo_name) {
                        sh "git push origin ${release_branch}"
                        sh "git push origin ${releaseTag}"
                    }

                }
            }
        }


        stage("Build Source") {
            steps {
                script {
                    if (repo_name in ['katello-installer', 'foreman-installer']) {
                        dir(repo_name) {
                            try {

                                configureRVM(ruby)

                                withRVM(['bundle install'], ruby)
                                withRVM(["FOREMAN_BRANCH=${version_map['foreman_branch']} rake pkg:generate_source"], ruby)

                                sources = sh(returnStdout: true, script: "ls pkg/*.tar.*").trim().split()
                                writeYaml(file: '../tool_belt/artifacts', data: sources.toList())

                            } finally {

                                cleanupRVM(ruby)

                            }
                        }
                    } else {

                        toolBelt(
                            command: 'release build-source',
                            config: tool_belt_config,
                            options: [
                                "--dir ../${repo_name}",
                                "--type ${sourceType}",
                                "--output-file artifacts"
                            ]
                        )
                    }
                }
            }
        }

        stage("Upload Source") {
            steps {
                script {

                    def artifact = ''
                    def artifact_path = ''

                    artifacts = readYaml(file: 'tool_belt/artifacts')

                    dir(repo_name) {
                        artifact_base_path = sh(returnStdout: true, script: 'pwd').trim()
                    }

                    for (i = 0; i < artifacts.size(); i += 1) {
                        artifact_path = artifact_base_path + '/' + artifacts[i]

                        runDownstreamPlaybook {
                            playbook = 'playbooks/upload_package.yml'
                            extraVars = [
                                'artifact': artifact_path,
                                'repo': version_map['repo'],
                                'product': 'Source Files',
                                'organization': 'Sat6-CI'
                            ]
                        }
                    }
                }
            }
        }

        stage("Mark BZs as needs_rpm") {
            steps {

                script {

                    def ids = []
                    def bzs = readJSON(file: 'tool_belt/bz_ids.json')

                    for (bz in bzs) {
                        ids << bz['id']
                    }

                    if (ids.size() > 0) {
                        ids = ids.join(' --bug ')

                        withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'bugzilla-credentials', passwordVariable: 'BZ_PASSWORD', usernameVariable: 'BZ_USERNAME']]) {

                            toolBelt(
                                command: 'bugzilla set-build-state',
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
        }

        stage("Trigger packaging update") {
            when {
                expression { packaging_job }
            }
            steps {
                script {
                    build job: packaging_job, parameters: [
                      [$class: 'StringParameterValue', name: 'project', value: repo_name],
                      [$class: 'StringParameterValue', name: 'version', value: releaseTag],
                      [$class: 'StringParameterValue', name: 'targetBranch', value: release_branch],
                    ]
                }
            }
        }
    }
}
