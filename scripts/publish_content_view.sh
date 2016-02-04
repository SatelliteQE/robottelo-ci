#!/bin/bash -xe

hammer --username ${SATELLITE_USERNAME} --password ${SATELLITE_PASSWORD} --server ${SATELLITE_SERVER} content-view publish --organization "${organization}" --name "${content_view_name}"
