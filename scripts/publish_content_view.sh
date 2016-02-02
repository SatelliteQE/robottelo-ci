#!/bin/bash -xe

hammer --username ${SATELLITE_USERNAME} --password ${SATELLITE_PASSWORD} --server ${SATELLITE_SERVER} content-view publish --organization "${organization}" --name "${content_view_name}"
version_id=`hammer --username ${SATELLITE_USERNAME} --password ${SATELLITE_PASSWORD} --server ${SATELLITE_SERVER} content-view version list --organization "${organization}" --content-view "${content_view_name}" | awk -F'|' '{print $1}' | sort -n  | tac | head -n 1`

cat > version_properties <<EOL
version_id=${version_id}
EOL
