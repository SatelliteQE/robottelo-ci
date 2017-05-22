
function code_coverage () {
    # Shutdown the Satellite6 services for collecting coverage.
    ssh -o StrictHostKeyChecking=no root@"${SERVER_HOSTNAME}" "katello-service stop"

    # Create tar file for each of the Tier .coverage files to create a consolidated coverage report.
    ssh -o StrictHostKeyChecking=no root@"${SERVER_HOSTNAME}" "cd /etc/coverage ; tar -cvf coverage.${ENDPOINT}.tar .coverage.*"

    # Combine the coverage output to a single file and create a xml file.
    ssh -o StrictHostKeyChecking=no "root@${SERVER_HOSTNAME}" "cd /etc/coverage/ ; coverage combine"
    ssh -o StrictHostKeyChecking=no "root@${SERVER_HOSTNAME}" "cd /etc/coverage/ ; coverage xml"

    # Fetch the coverage.xml file to the project folder.
    scp -o StrictHostKeyChecking=no -r "root@${SERVER_HOSTNAME}:/etc/coverage/coverage.xml" .

    # Fetch the coverage.${ENDPOINT}.tar file to the project folder.
    scp -o StrictHostKeyChecking=no -r "root@${SERVER_HOSTNAME}:/etc/coverage/coverage.${ENDPOINT}.tar" .
}

if [[ "${SATELLITE_DISTRIBUTION}" != *"UPSTREAM"* ]]; then
    code_coverage
fi
