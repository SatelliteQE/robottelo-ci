def kerberos_setup() {
    withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'jenkins-satellite-jenkins.rhev-ci-vms.eng.rdu2.redhat.com.keytab', passwordVariable: 'KRB5_KEYTAB_BASE64', usernameVariable: 'KRB5_KEYTAB_PRINCIPAL']]) {
        sh "echo ${KRB5_KEYTAB_BASE64} | base64 -d > JenkinsAccount.keytab"
        sh "kinit -kt JenkinsAccount.keytab ${KRB5_KEYTAB_PRINCIPAL}"
        sh "rm -f JenkinsAccount.keytab"
    }
}

def kerberos_cleanup() {
    sh "kdestroy"
    sh "rm -f JenkinsAccount.keytab"
}
