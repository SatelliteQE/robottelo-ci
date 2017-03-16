#!/bin/bash -exl

APP_ROOT=`pwd`

# RVM Ruby environment
# Use a gemset unique to each executor to enable parallel builds
gemset=$(echo ${JOB_NAME} | cut -d/ -f1)-${EXECUTOR_NUMBER}
rvm use ruby-${ruby}@${gemset} --create
rvm gemset empty --force

gem install bundler --no-ri --no-rdoc

bundle install
bundle exec rake test
