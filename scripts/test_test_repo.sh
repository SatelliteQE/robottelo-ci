#!/bin/bash -ex

cd plugin/

# RVM Ruby environment
. /etc/profile.d/rvm.sh
# Use a gemset unique to each executor to enable parallel builds
gemset=$(echo ${JOB_NAME} | cut -d/ -f1)-${EXECUTOR_NUMBER}
rvm use ruby-${ruby}@${gemset} --create
rvm gemset empty --force
gem update --no-ri --no-rdoc
gem install bundler --no-ri --no-rdoc

# Retry as rubygems (being external to us) can be intermittent
while ! bundle install --without=development; do
  (( c += 1 ))
  if [ $c -ge 5 ]; then
    echo "bundle install continually failed" >&2
    exit 1
  fi
done

bundle exec rake
