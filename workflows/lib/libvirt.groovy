def runOnLibvirtHost(action) {
    wrap([$class: 'AnsiColorBuildWrapper', colorMapName: "xterm"]) {
        sh "ssh jenkins@${env.LIBVIRT_HOST} \"${action}\""
    }
}

def test_forklift(args) {

    def os_versions = args.os_versions ?: ['7']
    def satellite_version = args.satellite_version

    runOnLibvirtHost "cd sat-deploy && git -c http.sslVerify=false fetch origin && git reset origin/master --hard"
    runOnLibvirtHost "cd sat-deploy/forklift && git -c http.sslVerify=false fetch origin && git reset origin/master --hard"
    runOnLibvirtHost "cd sat-deploy/forklift && echo 'libvirt_options: {volume_cache: unsafe}' > vagrant/settings.yaml"

    def branches = [:]

    wrap([$class: 'AnsiColorBuildWrapper', colorMapName: "xterm"]) {
        for (int i = 0; i < os_versions.size(); i++) {
            def index = i // fresh variable per iteration; i will be mutated
            def item = os_versions.get(index)
            def vars = ['pipeline_version': "${satellite_version}", 'pipeline_os': "rhel${item}"]
            def extra_vars = buildExtraVars(vars)

            branches["install-rhel-${item}"] = {
                try {
                    runOnLibvirtHost "cd sat-deploy && ansible-playbook pipelines/satellite_install_pipeline.yml -e forklift_state=up ${extra_vars}"
                } finally {
                    runOnLibvirtHost "cd sat-deploy && ansible-playbook pipelines/satellite_install_pipeline.yml -e forklift_state=destroy ${extra_vars}"
                }
            }
        }
    }

    parallel branches

}
