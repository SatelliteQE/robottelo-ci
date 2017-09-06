#!/bin/bash

if [[ $gitlabTargetBranch == 'SATELLITE-6.2.0' ]];then
  pushd foreman
  echo "gem 'foreman_docker', :git => 'https://${GIT_HOSTNAME}/${GIT_ORGANIZATION}/foreman_docker.git', :branch => '${gitlabTargetBranch}'" >> bundler.d/Gemfile.local.rb
  popd foreman
fi
