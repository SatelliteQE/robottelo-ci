#!/bin/bash -exl

APP_ROOT=`pwd`

# RVM Ruby environment
# Use a gemset unique to each executor to enable parallel builds
gemset=$(echo ${JOB_NAME} | cut -d/ -f1)-${EXECUTOR_NUMBER}
rvm use ruby-${ruby}@${gemset} --create
rvm gemset empty --force
# Update any gems from the global gemset
#gem update --no-ri --no-rdoc
gem install bundler --no-ri --no-rdoc

# Puppet environment
cat >> $APP_ROOT/Gemfile << EOF
gem 'facter'
gem 'puppet', '~> 3.8.0'
EOF

bundle install
bundle exec rake jenkins:unit
