node('sat6-rhel7') {
  try {
    stage("run cvmanager") {

        git url: "https://github.com/RedHatSatellite/katello-cvmanager"

        sh "bundle install --without=development"
        withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'artefact-satellite-credentials', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME']]) {
          timeout(time: 1, unit: 'HOURS') {
            sh "bundle exec ruby ./cvmanager clean --uri ${env.SATELLITE_SERVER} --user '${USERNAME}' --pass '${PASSWORD}' --organization-id=3 --no-verify-ssl --sequential 100"
          }
        }

    }
  } catch (e) {
    currentBuild.result = "FAILED"
    notifyFailed()
    throw e
  }
}

def notifyFailed() {
  emailext (
      subject: "FAILED: Job ${env.JOB_NAME} #${env.BUILD_NUMBER}",
      body: """FAILED: Job ${env.JOB_NAME} #${env.BUILD_NUMBER}:
Check console output at ${env.BUILD_URL}""",
      to: "${env.DOGFOOD_EMAIL_LIST}"
    )
}
