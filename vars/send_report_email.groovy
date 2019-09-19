#!/usr/bin/env groovy

/* Usage:
    send_report_email $buildStatus
    ex: send_report_email "automation" OR send_report_email "upgrade"
*/

def call(buildStatus) {
    // build status of null means successful
    buildStatus = buildStatus ?: 'automation'
    // define variables
    def subject = "subject"
    if (buildStatus == "automation") {
        subject = "Satellite ${env.satellite_version} Automation Report for ${env.os}"
    }
    else if (buildStatus == "upgrade") {
        subject = "Satellite ${env.satellite_version} Upgrade Tiers Automation Report for ${env.os}"
    }
    else if (buildStatus == "foreman-maintain") {
        subject = "Foreman-Maintain Automation Report ${COMPONENT} for ${BUILD_LABEL}"
    }
    script {
        make_venv python: defaults.python
        sh_venv '''
        pip install click jinja2
        wget https://raw.githubusercontent.com/SatelliteQE/robottelo-ci/master/lib/python/satellite6-automation-report.py
        [ ! -d "templates" ] && mkdir templates
        wget -O templates/email_report.html https://raw.githubusercontent.com/SatelliteQE/robottelo-ci/master/lib/python/templates/email_report.html
        python satellite6-automation-report.py *.xml > report.txt
        python satellite6-automation-report.py -o html *.xml > email_report.html
        '''
    }

    emailext (
      to: "${env.QE_EMAIL_LIST}",
      subject: subject,
      mimeType: 'text/html',
      body: '${FILE, path="email_report.html"}' + "The build ${env.BUILD_URL} has been completed."
    )
}

