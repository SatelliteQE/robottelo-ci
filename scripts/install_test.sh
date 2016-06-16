#!/bin/bash -xe

ssh jenkins@$LIBVIRT_HOST "cd sat-deploy && git -c http.sslVerify=false fetch origin && git reset origin/master --hard"
ssh jenkins@$LIBVIRT_HOST "cd sat-deploy/lago && ./install-satellite.rb rhel${rhel}"
