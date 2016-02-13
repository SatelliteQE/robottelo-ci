#!/bin/bash -xe

hammer --username ${SATELLITE_USERNAME} --password ${SATELLITE_PASSWORD} --server ${SATELLITE_SERVER} \
    repository synchronize --organization "${organization}" --product "${product}" --name "${repository}"
