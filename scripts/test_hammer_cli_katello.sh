#!/bin/bash -exl

# RVM Ruby environment
# Use a gemset unique to each executor to enable parallel builds
gemset=$(echo ${JOB_NAME} | cut -d/ -f1)-${EXECUTOR_NUMBER}
rvm use ruby-${ruby}@${gemset} --create
rvm gemset empty --force
gem update --no-ri --no-rdoc
gem install bundler --no-ri --no-rdoc

echo "gem 'rake'" >> Gemfile.local
echo "gem 'rubocop'" >> Gemfile.local
echo "gem 'mocha'" >> Gemfile.local
echo "gem 'minitest', '4.7.4'" >> Gemfile.local
echo "gem 'minitest-spec-context'" >> Gemfile.local

echo "gem 'hammer_cli', :git => 'https://${GIT_HOSTNAME}/${GIT_ORGANIZATION}/hammer_cli.git', :ref => '${gitlabTargetBranch}'" > Gemfile.local
echo "gem 'hammer_cli_foreman', :git => 'https://${GIT_HOSTNAME}/${GIT_ORGANIZATION}/hammer_cli_foreman.git', :ref => '${gitlabTargetBranch}'" >> Gemfile.local

bundle install

bundle exec rake test TESTOPTS="-v"
