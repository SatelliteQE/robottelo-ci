# Shutdown the Satellite6 services for collecting coverage.
ssh -o StrictHostKeyChecking=no root@"${SERVER_HOSTNAME}" "katello-service stop"

# Combine the coverage output to a single file and create a xml file.
ssh -o StrictHostKeyChecking=no "root@${SERVER_HOSTNAME}" "cd /etc/coverage/ ; coverage combine"
ssh -o StrictHostKeyChecking=no "root@${SERVER_HOSTNAME}" "cd /etc/coverage/ ; coverage xml"

# Fetch the coverage.xml file to the project folder.
scp -o StrictHostKeyChecking=no -r "root@${SERVER_HOSTNAME}:/etc/coverage/coverage.xml" .
