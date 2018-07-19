node('sat6-rhel7') {
    stage("Push to Open Platform") {
        withCredentials([string(credentialsId: 'GEMSNAP_OPEN_PAAS_WEBHOOK_URL', variable: 'GEMSNAP_OPEN_PAAS_WEBHOOK_URL')]) {
            sh "curl -k -XPOST ${GEMSNAP_63_OPEN_PAAS_WEBHOOK_URL}"
            sh "curl -k -XPOST ${GEMSNAP_64_OPEN_PAAS_WEBHOOK_URL}"
	}
    }
}
