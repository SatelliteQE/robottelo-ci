
function python_code_coverage () {
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

function ruby_code_coverage () {
    # Create tar file for each of the Tier Coverage Report files to create a consolidated coverage report.
    ssh -o StrictHostKeyChecking=no root@"${SERVER_HOSTNAME}" "cd /etc/coverage/ruby/tfm/reports/ ; tar -cvf /root/tfm_reports_${ENDPOINT}.tar ./."

    # Fetch the tfm_reports.${ENDPOINT}.tar file to the project folder.
    scp -o StrictHostKeyChecking=no -r "root@${SERVER_HOSTNAME}:/root/tfm_reports_${ENDPOINT}.tar" .
}

if [[ "${SATELLITE_DISTRIBUTION}" != *"UPSTREAM"* ]] && [[ "${DISTRO}" != "rhel6" ]]; then
    python_code_coverage

    if [[ "${RUBY_CODE_COVERAGE}" == "true" ]]; then
        ruby_code_coverage
    else
        touch /root/tfm_reports_${ENDPOINT}.tar
    fi
fi
