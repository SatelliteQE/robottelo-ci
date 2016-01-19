#!/bin/bash -ex

if [ -n "${gitlabSourceBranch}" ]; then
  git remote add pr https://$GIT_HOSTNAME/${gitlabSourceRepoName}.git
  git fetch pr
  git merge pr/${gitlabSourceBranch}
fi
