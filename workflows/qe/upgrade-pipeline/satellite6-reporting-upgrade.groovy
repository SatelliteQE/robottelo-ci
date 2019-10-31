@Library("github.com/SatelliteQE/robottelo-ci") _

pipeline {
    agent { label "sat6-${satellite_version}" }
    stages {
        stage('Clean Workspace') {
            steps {
                deleteDir()
            }
        }
        stage('Copy Artifacts') {
            steps {
                sh "rm -f *.xml"
                copyArtifacts(filter:'*-results.xml',
                    projectName: "automation-upgraded-${satellite_version}-all-tiers-${os}",
                    selector: lastSuccessful())
                copyArtifacts(filter:'*-results.xml',
                    projectName: "automation-upgraded-${satellite_version}-end-to-end-${os}",
                    selector: lastSuccessful())
                script {
                    currentBuild.displayName = "# ${env.BUILD_NUMBER} ${env.BUILD_LABEL}"
                }
            }
        }
    }
    post {
    success {
        send_report_email "upgrade"
    }
    }
}
