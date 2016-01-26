pip install -r requirements.txt

cat > jenkins_jobs.ini <<EOF
[job_builder]
keep_descriptions=False
include_path=.:scripts:foreman-infra
recursive=True
allow_duplicates=False
exclude=foreman-infra/yaml/jobs

[jenkins]
user=${JENKINS_USER}
password=${JENKINS_PASSWORD}
url=${JENKINS_MASTER_URL}
EOF

./setup_jjb.sh
./generate_jobs.sh
./update_job.sh

rm jenkins_jobs.ini
