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
                    projectName: "automation-${satellite_version}-tier1-${os}",
                    selector: lastSuccessful())
                copyArtifacts(filter:'*-results.xml',
                    projectName: "automation-${satellite_version}-tier2-${os}",
                    selector: lastSuccessful())
                copyArtifacts(filter:'*-results.xml',
                    projectName: "automation-${satellite_version}-tier3-${os}",
                    selector: lastSuccessful())
                copyArtifacts(filter:'*-results.xml',
                    projectName: "automation-${satellite_version}-tier4-${os}",
                    selector: lastSuccessful())
                copyArtifacts(filter:'*-results.xml',
                    projectName: "automation-${satellite_version}-destructive-${os}",
                    selector: lastSuccessful())
                copyArtifacts(filter:'*-results.xml',
                    projectName: "automation-${satellite_version}-rhai-${os}",
                    selector: lastSuccessful())
                script {
                    currentBuild.displayName = "# ${env.BUILD_NUMBER} ${env.BUILD_LABEL}"
                }
            }
        }
    }
    post {
    success {
        send_report_email "automation"
    }
    }
}
