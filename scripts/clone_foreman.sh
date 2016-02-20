#!/bin/bash -xe

if [ -d foreman ]; then
  rm -rf foreman
fi
git clone https://$GIT_HOSTNAME/$GIT_ORGANIZATION/foreman.git

pushd foreman
git fetch origin
git checkout origin/${gitlabTargetBranch}
popd foreman
