#!/bin/bash -xe

ssh jenkins@$LIBVIRT_HOST "cd forklift && vagrant destroy pipeline-sat-rhel${rhel} pipeline-capsule-rhel${rhel}"
