#!/bin/bash -e

ssh jenkins@$COMPOSE_HOST "cd satellite-packaging && git -c http.sslVerify=false fetch origin && git checkout origin/SATELLITE-${version}"
ssh jenkins@$COMPOSE_HOST "cd satellite-packaging/compose && ./generate-compose.sh ${rhel} /home/jenkins"
