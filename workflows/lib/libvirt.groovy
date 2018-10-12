def runOnLibvirtHost(action) {
    wrap([$class: 'AnsiColorBuildWrapper', colorMapName: "xterm"]) {
        sh "ssh jenkins@${env.LIBVIRT_HOST} \"${action}\""
    }
}

def test_forklift(args) {

    def os_versions = args.os_versions ?: ['7']
    def sattellite_version = args.sattellite_version

    runOnLibvirtHost "cd sat-deploy && git -c http.sslVerify=false fetch origin && git reset origin/master --hard"
    runOnLibvirtHost "cd sat-deploy/forklift && git -c http.sslVerify=false fetch origin && git reset origin/master --hard"

    def branches = [:]

    wrap([$class: 'AnsiColorBuildWrapper', colorMapName: "xterm"]) {
        for (int i = 0; i < os_versions.size(); i++) {
            def index = i // fresh variable per iteration; i will be mutated
            def item = os_versions.get(index)

            branches["install-rhel-${item}"] = {
                try {
                    runOnLibvirtHost "cd sat-deploy && ansible-playbook pipelines/compose_test_${satellite_version}_rhel${item}.yml -e forklift_state=up"
                } finally {
                    runOnLibvirtHost "cd sat-deploy && ansible-playbook pipelines/compose_test_${satellite_version}_rhel${item}.yml -e forklift_state=destroy"
                }
            }
        }
    }

    parallel branches

}
