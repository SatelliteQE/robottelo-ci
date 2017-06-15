node('sat6-rhel7') {

    stage("Push to Openshift") {

        git url: "https://${env.GIT_HOSTNAME}/satellite6/ohsnap.git"

        sh "git remote rm openshift || true"
        sh "git remote add openshift ${env.OHSNAP_OPENSHIFT_GIT_REPO}"
        sh "git push openshift master:master --force"

    }
}
