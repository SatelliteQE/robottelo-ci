node('sat6-build') {
  stage('one') {
    sh "echo Maybe?"
  }

  stage('two') {
    sh 'exit 1'
  }
}
