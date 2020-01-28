node('sat6-build') {
    stage("Push to Open Platform") {
    	sh "curl -k -XPOST ${GEMSNAP_64_PSI_WEBHOOK_URL}"
    	sh "curl -k -XPOST ${GEMSNAP_65_PSI_WEBHOOK_URL}"
    	sh "curl -k -XPOST ${GEMSNAP_66_PSI_WEBHOOK_URL}"
    }
}
