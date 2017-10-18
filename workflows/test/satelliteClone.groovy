node('rhel') {

   // ssh into bread.usersys.redhat.com
   // cd ~/dolly
   // run ./jenkins/run_dolly.rb <pr_number>
   // check exit code
    stage("Run Clones") {
        runOnBread("cd ~/dolly; ./jenkins/run_dolly.rb ${pr_number}")
    }
}

def runOnBread(action) {
    sh "ssh jomitsch@${env.BREAD_HOST} \"${action}\""
}
