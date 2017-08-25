node('sat6-rhel7') {
  snapperStage {
    sh "echo Maybe?"
  }

  snapperStage {
    sh 'exit 1'
  }
}
