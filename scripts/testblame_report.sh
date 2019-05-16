sh setup.sh
dir_path=$PWD
mkdir clone
testblame set-config --git-url="https://github.com/SatelliteQE/robottelo" --jenkins-url ${JENKINS_JOB_URL} --clone-path ${dir_path}/clone/
testblame send-email-report --with-link=yes --from_email=testblame@example.com --to_email=user@example.com --subject="Testing Result" --component robottelo_component.json --local-repo=${dir_path}/clone/
