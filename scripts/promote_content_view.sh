#!/bin/bash -xe

version_id=`hammer --username ${SATELLITE_USERNAME} --password ${SATELLITE_PASSWORD} --server ${SATELLITE_SERVER} content-view version list --organization "${organization}" --content-view "${content_view_name}" --environment "${from_lifecycle_environment}" | awk -F'|' '{print $1}' | sort -n  | tac | head -n 1`

hammer --username ${SATELLITE_USERNAME} --password ${SATELLITE_PASSWORD} --server ${SATELLITE_SERVER} \
    content-view version promote --to-lifecycle-environment "${lifecycle_environment}" --organization \
    "${organization}" --content-view "${content_view_name}" --id "${version_id}"
