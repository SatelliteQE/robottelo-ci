node('sat6-rhel7') {
  stage('one') {
    sh "echo Maybe?"
  }

  stage('two') {
    sh 'exit 1'
  }
}
