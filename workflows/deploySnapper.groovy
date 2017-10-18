node('sat6-rhel7') {
    stage("Push to Open Platform") {
        withCredentials([string(credentialsId: 'SNAPPER_OPEN_PAAS_WEBHOOK_URL', variable: 'SNAPPER_OPEN_PAAS_WEBHOOK_URL')]) {
            sh "curl -k -XPOST ${SNAPPER_OPEN_PAAS_WEBHOOK_URL}"
	}
    }
}
