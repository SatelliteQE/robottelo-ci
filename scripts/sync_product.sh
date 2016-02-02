#!/bin/bash -xe

hammer --username ${SATELLITE_USERNAME} --password ${SATELLITE_PASSWORD} --server ${SATELLITE_SERVER} product synchronize --organization "${organization}" --name "${product_name}"
