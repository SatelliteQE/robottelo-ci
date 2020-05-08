def virtEnv3(path, command) {
  dir(path) {
      if(!fileExists('venv')) {
          sh "python3 -m venv venv"
      }

      sh """
      source venv/bin/activate
      ${command}
      deactivate
      """
  }
}

def setup_workspace() {
  deleteDir()
  dir ('ci') {
      checkout([
          $class : 'GitSCM',
          branches : [[name: 'master']],
          extensions: [[$class: 'CleanCheckout']],
          userRemoteConfigs: [
              [url: "https://${env.GIT_HOSTNAME}/${env.GIT_ORGANIZATION}/katello-team.git"]
          ]
      ])
  }

  virtEnv3('./ci', 'pip install -r scripts/requirements.txt')
}

def notify(text) {
  emailext(
    subject: "${text}",
    attachLog: true,
    from: "pm-sat@redhat.com",
    to: "${env.BZ_JOB_EMAIL_LIST}"
  )
}
