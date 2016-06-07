#!/bin/bash -xe

ssh jenkins@$LIBVIRT_HOST "cd sat-deploy && git -c http.sslVerify=false fetch origin && git reset origin/master --hard"
ssh jenkins@$LIBVIRT_HOST "cd sat-deploy/lago/environment-rhel${rhel} && lago revert initial"
ssh jenkins@$LIBVIRT_HOST "cd sat-deploy/lago/environment-rhel${rhel} && lago snapshot initial"
ssh jenkins@$LIBVIRT_HOST "cd sat-deploy/lago && ./install-satellite.rb rhel${rhel}"
