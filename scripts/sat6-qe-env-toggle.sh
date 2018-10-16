pip install -r requirements.txt

# Replace all the instances of list email to user email
if [[ "${ENVIRONMENT}" == 'TEST' ]]; then

    for file in `grep -ir 'QE_EMAIL_LIST' | cut -d ":" -f 1`; do

        sed -i 's/QE_EMAIL_LIST/BUILD_USER_EMAIL/g' $file;

    done

fi

#TODO Write the implementation to disable Polarion related Jobs

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
