#!/usr/bin/env groovy

/* Usage:
    send_automation_email $buildStatus
    ex: send_automation_email "success"
*/
def call(buildStatus) {
    // build status of null means successful
    buildStatus = buildStatus ?: 'success'
    // define variables
    def subject = "subject"
    def body = "body"
    if (buildStatus == "failure") {
        body = "This build ${env.BUILD_URL} is Failed. Please check failure and re-trigger the job."
        subject = "[Jenkins] ${env.JOB_NAME} Build #${env.BUILD_NUMBER} Failed"
    }
    else if (buildStatus == "fixed") {
        body = "This build ${env.BUILD_URL} is Successful."
        subject = "[Jenkins] ${env.JOB_NAME} Build #${env.BUILD_NUMBER} Fixed"
    }
    else if (buildStatus == "success") {
        body = "This build ${env.BUILD_URL} is Successful."
        subject = "[Jenkins] ${env.JOB_NAME} Build #${env.BUILD_NUMBER} Passed"
    }

    emailext (
      to: "${env.QE_EMAIL_LIST}",
      subject: subject,
      body: body,
    )
}

