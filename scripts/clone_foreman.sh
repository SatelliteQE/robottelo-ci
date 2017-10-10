#!/bin/bash -xe

if [ -d foreman ]; then
  rm -rf foreman
fi
git clone https://$GIT_HOSTNAME/$GIT_ORGANIZATION/foreman.git

pushd foreman
git fetch origin
git checkout origin/${gitlabTargetBranch}

# Change the gem source if it's for Sat-6.3.0
if [ ${gitlabTargetBranch} == 'SATELLITE-6.3.0' ]; then
  sed -i "s/https:\/\/rubygems.org/${GEMSNAP_URL}/g" Gemfile
fi

popd foreman
