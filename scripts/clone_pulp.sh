#!/bin/bash -xe

if [ -d pulp ]; then
  rm -rf pulp
fi
git clone https://$GIT_HOSTNAME/$GIT_ORGANIZATION/pulp.git

pushd pulp
git fetch origin
git checkout origin/${gitlabTargetBranch}
popd pulp
