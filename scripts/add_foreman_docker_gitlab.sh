#!/bin/bash

pushd foreman
echo "gem 'foreman_docker', :git => 'https://${GIT_HOSTNAME}/${GIT_ORGANIZATION}/foreman_docker.git', :branch => '${gitlabTargetBranch}'" >> bundler.d/Gemfile.local.rb
popd foreman
