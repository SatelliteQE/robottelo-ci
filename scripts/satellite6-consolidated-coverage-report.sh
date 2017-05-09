pip install coverage

mkdir -p ${PWD}/coverage ; cd ${PWD}/coverage/
for i in tier1 tier2 tier3 tier4 rhai destructive; do
    tar -xvf ../coverage.$i.tar
done

cat > .coveragerc <<EOF
[run]
source=
    pulp
    pulp_deb
    pulp_docker
    pulp_openstack
    pulp_ostree
    pulp_puppet
    pulp_python
    pulp_rpm

data_file=${PWD}/.coverage

parallel=true

concurrency=
    multiprocessing
    thread

[xml]
output=${PWD}/coverage.xml
EOF

coverage combine

scp -o StrictHostKeyChecking=no "${PWD}"/.coverage "root@${SERVER_HOSTNAME}:/etc/coverage/"
ssh -o StrictHostKeyChecking=no "root@${SERVER_HOSTNAME}" "cd /etc/coverage/ ; coverage report > coverage_report.txt"
ssh -o StrictHostKeyChecking=no "root@${SERVER_HOSTNAME}" "cd /etc/coverage/ ; coverage xml"

scp -o StrictHostKeyChecking=no -r "root@${SERVER_HOSTNAME}:/etc/coverage/coverage_report.txt" .
scp -o StrictHostKeyChecking=no -r "root@${SERVER_HOSTNAME}:/etc/coverage/coverage.xml" .
