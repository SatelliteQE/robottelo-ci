node('rhel') {

    snapperStage('Run Tests') {

        def tests = [
            "puppet-3.8/ruby-2.0.0": {
                node('rhel') {
                    def gemset = 'puppet-3.8-ruby-2.0.0'

                    try {

                        wrap([$class: 'AnsiColorBuildWrapper', colorMapName: "xterm"]) {
                            deleteDir()
                            gitlab_clone_and_merge(puppet_repo)

                            withRVM(["gem install bundler"], '2.0.0', gemset)
                            withRVM(["PUPPET_VERSION=3.8 bundle install --without system_tests development"], '2.0.0', gemset)
                            withRVM(["ONLY_OS=redhat-6-x86_64,redhat-7-x86_64 bundle exec rake"], '2.0.0', gemset)
                        }

                    } finally {

                        cleanup_rvm(gemset)

                    }
                }
            }
        ]

        if (gitlabTargetBranch == 'SATELLITE-6.2.0') {

            tests["puppet-3.8/ruby-1.8.7"] = {
                node('rhel') {
                    def gemset = 'puppet-3.8-ruby-1.8.7'

                    try {

                        wrap([$class: 'AnsiColorBuildWrapper', colorMapName: "xterm"]) {
                            deleteDir()
                            gitlab_clone_and_merge(puppet_repo)

                            withRVM(["gem install bundler"], '1.8.7', gemset)
                            withRVM(["PUPPET_VERSION=3.8 bundle install --without system_tests development"], '1.8.7', gemset)
                            withRVM(["ONLY_OS=redhat-6-x86_64,redhat-7-x86_64 bundle exec rake"], '1.8.7', gemset)
                        }

                    } finally {

                        cleanup_rvm(gemset)

                    }
                }
            }

        } else if (gitlabTargetBranch == "SATELLITE-6.3.0") {

            tests["puppet-4.10.7/ruby-2.1.9"] = {
                node('rhel') {
                    def gemset = 'puppet-4.10.7-ruby-2.1.9'

                    try {

                        wrap([$class: 'AnsiColorBuildWrapper', colorMapName: "xterm"]) {
                            deleteDir()
                            gitlab_clone_and_merge(puppet_repo)

                            withRVM(["gem install bundler"], '2.1.9', gemset)
                            withRVM(["PUPPET_VERSION=3.8 bundle install --without system_tests development"], '2.1.9', gemset)
                            withRVM(["ONLY_OS=redhat-7-x86_64 bundle exec rake"], '2.1.9', gemset)
                        }

                    } finally {

                        cleanup_rvm(gemset)

                    }
                }
            }

        }

        parallel tests

    }

}
