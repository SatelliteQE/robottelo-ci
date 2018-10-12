def runOnLibvirtHost(action) {
    wrap([$class: 'AnsiColorBuildWrapper', colorMapName: "xterm"]) {
        sh "ssh jenkins@${env.LIBVIRT_HOST} \"${action}\""
    }
}
