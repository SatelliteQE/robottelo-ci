#!/bin/bash -xe

ssh jenkins@$LIBVIRT_HOST "cd katello-deploy/plugins/sat-deploy && git -c http.sslVerify=false fetch origin && git reset origin/master --hard"
ssh jenkins@$LIBVIRT_HOST "cd katello-deploy/plugins/sat-deploy/templates && ./build.rb satellite-rhel${rhel}"
