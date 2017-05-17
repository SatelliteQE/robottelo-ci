stage "Push to Openshift"
node('sat6-rhel7') {
            
    git url: "https://${env.GIT_HOSTNAME}/satellite6/mission-control.git"

    sh "git remote rm openshift || true"
    sh "git remote add openshift ${env.MISSION_CONTROL_OPENSHIFT_GIT_REPO}"
    sh "git push openshift master:master --force"

}
