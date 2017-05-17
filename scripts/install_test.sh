#!/bin/bash -xe

ssh jenkins@$LIBVIRT_HOST "cd forklift && vagrant destroy sat-628-rhel${rhel} pipeline-capsule-rhel${rhel}"
ssh jenkins@$LIBVIRT_HOST "cd forklift && git -c http.sslVerify=false fetch origin && git reset origin/master --hard"
ssh jenkins@$LIBVIRT_HOST "cd forklift/plugins/sat-deploy && git -c http.sslVerify=false fetch origin && git reset origin/master --hard"
ssh jenkins@$LIBVIRT_HOST "cd forklift && ansible-playbook plugins/sat-deploy/playbooks/pipeline_satellite_62_rhel${rhel}.yml"
