#!/bin/bash

if [[ ! -e jenkins_jobs.ini ]]; then
  cp jenkins_jobs.ini.sample jenkins_jobs.ini
fi

rm -rf foreman-infra
rm -rf _build
mkdir _build
cd _build

#TODO: Change this to main foreman-infra repository once all job configurations
#      are accepted there
git clone https://github.com/ehelms/foreman-infra.git --branch test-katello-core
cd foreman-infra
git cherry-pick 472661da3aa4fa8c2763c83b6c88c066d1f89c7c
cd ..

cd ..
cp -rf _build/foreman-infra/puppet/modules/jenkins_job_builder/files/theforeman.org foreman-infra
rm -rf _build
