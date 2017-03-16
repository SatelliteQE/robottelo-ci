#!/bin/bash -exl

# RVM Ruby environment
# Use a gemset unique to each executor to enable parallel builds
gemset=$(echo ${JOB_NAME} | cut -d/ -f1)-${EXECUTOR_NUMBER}
rvm use ruby-${ruby}@${gemset} --create
rvm gemset empty --force
gem install bundler --no-ri --no-rdoc

rm Gemfile
cat > Gemfile <<EOL
source 'https://rubygems.org'

gemspec :name => 'smart_proxy_remote_execution_ssh_core'

gem 'smart_proxy', :git => 'https://${GIT_HOSTNAME}/${GIT_ORGANIZATION}/smart-proxy.git', :ref => '${gitlabTargetBranch}'
gem 'smart_proxy_dynflow', :git => 'https://${GIT_HOSTNAME}/${GIT_ORGANIZATION}/smart_proxy_dynflow.git', :ref => '${gitlabTargetBranch}'

# load local gemfile
local_gemfile = File.join(File.dirname(__FILE__), 'Gemfile.local.rb')
self.instance_eval(Bundler.read_file(local_gemfile)) if File.exist?(local_gemfile)
EOL

bundle install
bundle exec rake test
