#!/bin/bash -exl

# RVM Ruby environment
# Use a gemset unique to each executor to enable parallel builds
gemset=$(echo ${JOB_NAME} | cut -d/ -f1)-${EXECUTOR_NUMBER}
rvm use ruby-${ruby}@${gemset} --create
rvm gemset empty --force
gem install bundler --no-ri --no-rdoc

PUPPET_VERSION=${puppet} bundle install --without system_tests development

ONLY_OS=redhat-6-x86_64,redhat-7-x86_64 bundle exec rake
