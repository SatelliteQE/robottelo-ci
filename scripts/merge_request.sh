#!/bin/bash -ex

if [ -n "${gitlabSourceBranch}" ]; then
  if [ -d plugin ];then
    pushd plugin
  fi

  git remote add pr https://$GIT_HOSTNAME/${gitlabSourceNamespace:-}/${gitlabSourceRepoName}.git
  git fetch pr
  git merge pr/${gitlabSourceBranch}

  if [ -d '../plugin' ];then
    popd
  fi
fi
