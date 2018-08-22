node('sat6-build') {
    stage("Push to Open Platform") {
        withCredentials([string(credentialsId: 'OHSNAP_OPEN_PAAS_WEBHOOK_URL', variable: 'OHSNAP_OPEN_PAAS_WEBHOOK_URL')]) {
            sh "curl -k -XPOST ${OHSNAP_OPEN_PAAS_WEBHOOK_URL}"
	}
    }
}
