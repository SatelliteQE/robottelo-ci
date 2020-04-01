def runOnLibvirtHost(action) {
    wrap([$class: 'AnsiColorBuildWrapper', colorMapName: "xterm"]) {
        sh "ssh jenkins@${env.LIBVIRT_HOST} \"${action}\""
    }
}

def test_forklift(args) {

    def os_versions = args.os_versions ?: ['7']
    def satellite_product = args.satellite_product
    def satellite_version = args.satellite_version

    runOnLibvirtHost "cd sat-deploy && git -c http.sslVerify=false fetch origin && git reset origin/master --hard"
    runOnLibvirtHost "cd sat-deploy/forklift && git -c http.sslVerify=false fetch origin && git reset origin/master --hard"
    runOnLibvirtHost "cd sat-deploy/forklift && echo 'libvirt_options: {volume_cache: unsafe}' > vagrant/settings.yaml"

    def branches = [:]

    wrap([$class: 'AnsiColorBuildWrapper', colorMapName: "xterm"]) {
        for (int i = 0; i < os_versions.size(); i++) {
            def index = i // fresh variable per iteration; i will be mutated
            def item = os_versions.get(index)
            def vars = ['pipeline_type': "${satellite_product}", 'pipeline_version': "${satellite_version}", 'pipeline_os': "rhel${item}"]
            def extra_vars = buildExtraVars(extraVars: vars)

            branches["install-rhel-${item}"] = {
                try {
                    runOnLibvirtHost "cd sat-deploy && ansible-playbook pipelines/${satellite_product}_install_pipeline.yml -e forklift_state=up ${extra_vars}"
                } finally {
                    try {
                        runOnLibvirtHost "cd sat-deploy && ansible-playbook forklift/playbooks/collect_debug.yml -l 'pipeline-*-${satellite_version}-rhel${item}' ${extra_vars}"
                    } finally {
                        runOnLibvirtHost "cd sat-deploy && ansible-playbook pipelines/${satellite_product}_install_pipeline.yml -e forklift_state=destroy ${extra_vars}"
                    }

                    def debug_folder = "debug-${satellite_product}-${satellite_version}-rhel${item}"

                    dir(debug_folder){

                        sh "scp -r jenkins@${env.LIBVIRT_HOST}:/tmp/${debug_folder}/ ."

                        archiveArtifacts artifacts: "**/*.tap", allowEmptyArchive: true
                        archiveArtifacts artifacts: "**/*.tar.xz", allowEmptyArchive: true
                        archiveArtifacts artifacts: "**/*.xml", allowEmptyArchive: true

                        runOnLibvirtHost "rm -rf /tmp/${debug_folder}/"

                        deleteDir()
                    }
                }
            }
        }
    }

    parallel branches

}
