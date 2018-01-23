node('rvm') {

    def tests = [:]

    for (int i = 0; i < puppet_ruby.size(); i++) {
        int index = i;
        def combo = puppet_ruby[index];

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
                            withRVM(["PUPPET_VERSION=${combo['puppet_version']} ONLY_OS=redhat-6-x86_64,redhat-7-x86_64 bundle exec rake"], combo['ruby_version'], name)
                        }
                    }

                } finally {

                    cleanup_rvm(name)

                }
            }
        }
    }

    stage('Run Tests') {

        gitlabCommitStatus() {
            parallel tests
        }

    }

}
