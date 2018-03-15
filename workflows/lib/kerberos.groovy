def kerberos_setup() {
    def krbcc = sh(script: "mktemp ${pwd()}/.krbcc.XXXXXX", returnStdout: true).trim()

    withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'jenkins-satellite-jenkins.rhev-ci-vms.eng.rdu2.redhat.com.keytab', passwordVariable: 'KRB5_KEYTAB_BASE64', usernameVariable: 'KRB5_KEYTAB_PRINCIPAL']]) {
        withEnv(["KRB5CCNAME=${krbcc}"]) {
            sh "echo ${KRB5_KEYTAB_BASE64} | base64 -d > JenkinsAccount.keytab"
            sh "kinit -kt JenkinsAccount.keytab ${KRB5_KEYTAB_PRINCIPAL}"
            sh "rm -f JenkinsAccount.keytab"
        }
    }

    return krbcc
}

def kerberos_cleanup(krbcc) {
    withEnv(["KRB5CCNAME=${krbcc}"]) {
        sh "kdestroy"
    }
    sh "rm -f JenkinsAccount.keytab"
    sh "rm -f ${krbcc}"
}
