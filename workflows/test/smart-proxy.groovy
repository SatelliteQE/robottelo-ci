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
                        gitlab_clone_and_merge('smart-proxy')

                        gitlabCommitStatus(name) {
                            sh "cp config/settings.yml.example config/settings.yml"
                            sh "sed -i \"/^\\s*gem.*puppet/ s/\\\$/, '~> ${combo['puppet_version']}'/\" bundler.d/puppet.rb"
                            withRVM(["gem install bundler"], combo['ruby_version'], name)
                            withRVM(["bundle install --without development"], combo['ruby_version'], name)
                            withRVM(["bundle exec rake pkg:generate_source jenkins:unit"], combo['ruby_version'], name)
                        }
                    }

                } finally {

                    archive "Gemfile.lock pkg/*"
                    junit keepLongStdio: true, testResults: 'jenkins/reports/unit/*.xml'

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
