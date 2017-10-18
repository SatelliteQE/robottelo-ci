node('rhel') {

    def tests = [:]
    def puppet_ruby = [
        [puppet_version: '3.8', ruby_version: '1.8.7', satellite_versions: ['6.2.0']],
        [puppet_version: '3.8', ruby_version: '2.0.0', satellite_versions: ['6.2.0', '6.3.0']],
        [puppet_version: '4.10.7', ruby_version: '2.1.9', satellite_versions: ['6.3.0']]
    ]

    for (combo in puppet_ruby) {
        if (!combo['satellite_versions'].contains(gitlabTargetBranch.minus('SATELLITE-'))) {
            continue
        }

        def name = "puppet-${combo['puppet_version']}_ruby-${combo['ruby_version']}"
        updateGitlabCommitStatus name: name, state: 'pending'

        tests[name] = {
            node('rhel') {

                try {

                    wrap([$class: 'AnsiColorBuildWrapper', colorMapName: "xterm"]) {
                        deleteDir()
                        gitlab_clone_and_merge(puppet_repo)

                        gitlabCommitStatus(name) {
                            withRVM(["gem install bundler"], combo['ruby_version'], name)
                            withRVM(["PUPPET_VERSION=${combo['puppet_version']} bundle install --without system_tests development"], combo['ruby_version'], name)
                            withRVM(["ONLY_OS=redhat-6-x86_64,redhat-7-x86_64 bundle exec rake"], combo['ruby_version'], name)
                        }
                    }

                } finally {

                    cleanup_rvm(name)

                }
            }
        }
    }

    snapperStage('Run Tests') {

        gitlabCommitStatus() {
            parallel tests
        }

    }

}
