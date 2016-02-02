#!/bin/bash

ssh jenkins@$SOURCE_FILE_HOST "cd satellite-packaging && git checkout SATELLITE-${version} && cd compose && ./generate-compose.sh ${rhel}"
