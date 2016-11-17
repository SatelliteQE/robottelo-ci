#!/bin/bash

pushd foreman
echo "gem 'bastion', :git => 'https://${GIT_HOSTNAME}/${GIT_ORGANIZATION}/bastion.git', :branch => '${gitlabTargetBranch}'" >> bundler.d/Gemfile.local.rb
popd foreman
