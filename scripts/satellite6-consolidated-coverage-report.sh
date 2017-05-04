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
coverage report > coverage_report.txt
coverage xml
