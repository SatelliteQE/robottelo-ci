#!/bin/bash

if [[ ! -e jenkins_jobs.ini ]]; then
  cp jenkins_jobs.ini.sample jenkins_jobs.ini
fi

rm -rf foreman-infra
rm -rf _build
mkdir _build
cd _build

git clone --depth 1 https://github.com/theforeman/foreman-infra.git
pushd foreman-infra
git grep -l '/etc/profile.d/rvm.sh' | grep -v yaml |xargs sed -i '1 s|^.*$|#!/bin/bash -exl|; s|\. /etc/profile.d/rvm.sh||'
popd

cd ..

cp -rf _build/foreman-infra/puppet/modules/jenkins_job_builder/files/theforeman.org foreman-infra
rm -rf _build

# Clean up foreman-infra defaults and jobs
rm -rf foreman-infra/yaml/{defaults,jobs}
