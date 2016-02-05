#!/bin/bash

ssh jenkins@$SOURCE_FILE_HOST "cd satellite-packaging && git -c http.sslVerify=false fetch origin && git checkout origin/SATELLITE-${version} && cd compose && ./generate-compose.sh ${rhel}"
