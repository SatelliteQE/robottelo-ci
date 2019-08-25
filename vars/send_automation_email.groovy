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
        subject = "The Build Number ${env.BUILD_NUMBER} of JOB ${env.JOB_NAME} is Failed."
    }
    else if (buildStatus == "fixed") {
        body = "This build ${env.BUILD_URL} is Successful."
        subject = "The Build Number ${env.BUILD_NUMBER} of JOB ${env.JOB_NAME} is Fixed."
    }
    else if (buildStatus == "success") {
        body = "This build ${env.BUILD_URL} is Successful."
        subject = "The Build Number ${env.BUILD_NUMBER} of JOB ${env.JOB_NAME} is Passed."
    }

    emailext (
      to: "${env.QE_EMAIL_LIST}",
      subject: subject,
      body: body,
    )
}

