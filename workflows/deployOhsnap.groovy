node('sat6-rhel7') {

    stage("Push to Openshift") {

        git url: "https://${env.GIT_HOSTNAME}/satellite6/ohsnap.git"

        sh "git remote rm openshift || true"
        sh "git remote add openshift ${env.OHSNAP_OPENSHIFT_GIT_REPO}"
        sh "git push openshift master:master --force"

    }

    stage("Push to Open Platform") {
        withCredentials([string(credentialsId: 'OHSNAP_OPEN_PAAS_WEBHOOK_URL', variable: 'OHSNAP_OPEN_PAAS_WEBHOOK_URL')]) {
            sh "curl -k -XPOST ${OHSNAP_OPEN_PAAS_WEBHOOK_URL}"
	}
    }
}
