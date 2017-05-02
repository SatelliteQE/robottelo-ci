#!/bin/bash -exl

# RVM Ruby environment
# Use a gemset unique to each executor to enable parallel builds
gemset=$(echo ${JOB_NAME} | cut -d/ -f1)-${EXECUTOR_NUMBER}
rvm use ruby-${ruby}@${gemset} --create
rvm gemset empty --force
gem install bundler --no-ri --no-rdoc

sed -e '/gem .*smart_proxy/ s/^#*/#/' -i Gemfile

echo "gem 'smart_proxy', :git => 'https://${GIT_HOSTNAME}/${GIT_ORGANIZATION}/smart-proxy.git', :ref => '${gitlabTargetBranch}'" > Gemfile.local.rb

bundle install
bundle exec rake test
