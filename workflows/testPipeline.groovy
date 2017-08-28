node('sat6-rhel7') {
  snapperStage('one') {
    sh "echo Maybe?"
  }

  snapperStage('two') {
    sh 'exit 1'
  }
}
