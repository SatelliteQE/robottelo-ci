#!/bin/bash -xe

hammer --username ${SATELLITE_USERNAME} --password ${SATELLITE_PASSWORD} --server ${SATELLITE_SERVER} \
    content-view version promote --to-lifecycle-environment "${lifecycle_environment}" --organization \
    "${organization}" --content-view "${content_view_name}" --id "${version_id}"
