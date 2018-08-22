node('sat6-build') {
    stage("Run GitLab clean") {
        try {
            sh "curl -k -o clean.json ${OHSNAP_URL}/api/gitlab/clean"
            archive "clean.json"
        }
        finally {
            deleteDir()
        }
    }
}
