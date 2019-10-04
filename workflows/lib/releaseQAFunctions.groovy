// Library Methods

def copyActivationKey(args) {

    runDownstreamPlaybook {
      playbook = 'playbooks/copy_activation_key.yml'
      extraVars = [
          'activation_key_name': args.activation_key,
          'organization': args.organization,
          'lifecycle_environment': args.lifecycle_environment,
      ]
    }

}

def promoteContentView(args) {

    runDownstreamPlaybook {
      playbook = 'playbooks/promote_content_view.yml'
      extraVars = [
          'content_view_name': args.content_view,
          'organization': args.organization,
          'to_lifecycle_environment': args.to_lifecycle_environment,
          'from_lifecycle_environment': args.from_lifecycle_environment,
      ]
    }
}

def createLifecycleEnvironment(args) {

    runDownstreamPlaybook {
      playbook = 'playbooks/create_lifecycle_environment.yml'
      extraVars = [
          'lifecycle_environment_name': args.name,
          'organization': args.organization,
          'prior': args.prior,
      ]
    }
}

def compareContentViews(args) {

    def archive_file = 'package_report.yaml'

    toolBelt(
        command: 'release compare-content-view',
        options: [
            "--content-view '${args.content_view}'",
            "--from-environment '${args.from_lifecycle_environment}'",
            "--to-environment '${args.to_lifecycle_environment}'",
            "--output '${archive_file}'"
        ],
        archive_file: archive_file
    )

}

def generateSnapVersion(args) {

    def snap_version = args.snap_version

    if (!snap_version) {
        def response = httpRequest url: "${OHSNAP_URL}/api/releases/${args.release_name}/snaps/new"
        def snap_data = readJSON text: response.content
        snap_version = "${snap_data['version']}"
    }

    return snap_version
}

def move_to_on_qa(args) {
    withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'bugzilla-credentials', passwordVariable: 'BZ_PASSWORD', usernameVariable: 'BZ_USERNAME']]) {

        toolBelt(
            command: 'bugzilla move-to-on-qa',
            options: [
                "--bz-username ${env.BZ_USERNAME}",
                "--bz-password ${env.BZ_PASSWORD}",
                "--version ${args.version}",
                "--snap ${args.snap_version}",
                "--commit"
            ]
        )
    }
}

def send_snap_mail(args) {

    emailext (
      subject: "Satellite ${args.version} Snap ${args.snap_version} -- HANDOFF TO QE",
      body: """Hi,

      Satellite ${args.version} snap ${args.snap_version} was released.

      For detailed information including installation instructions, BZs included, and updated package lists please see:
      ${env.OHSNAP_URL}/streams/${args.release_stream}/releases/${args.release_version}/snaps/${args.snap_version}/installation

      Thanks,
      S. Nappy
      """,
      to: "${env.SNAP_EMAIL_LIST}"
    )

}

def generate_snap_data(args) {

    def packages_file = args.packages_file ?: 'package_report.yaml'
    def output_file = args.output_file ?: 'snap.yaml'

    withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'bugzilla-credentials', passwordVariable: 'BZ_PASSWORD', usernameVariable: 'BZ_USERNAME']]) {
        withCredentials([string(credentialsId: 'gitlab-jenkins-user-api-token-string', variable: 'GITLAB_TOKEN')]) {

            toolBelt(
                command: 'release snap',
                config: "./configs/${args.release_name}/",
                options: [
                    "--version ${args.release_stream}",
                    "--milestone ${args.release_version}",
                    "--snap ${args.snap_version}",
                    "--gitlab-username jenkins",
                    "--gitlab-token ${env.GITLAB_TOKEN}",
                    "--bz-username ${env.BZ_USERNAME}",
                    "--bz-password ${env.BZ_PASSWORD}",
                    "--packages-file ${packages_file}",
                    "--output-file ${output_file}",
                    "--commit"
                ],
                archive_file: output_file
            )

        }
    }
}

def release_snap(args) {

    move_to_on_qa(
        version: "${args.release_version}",
        snap_version: args.snap_version
    )

    generate_snap_data(
        version: "${args.release_name}/${args.release_version}",
        release_name: args.release_name,
        release_version: args.release_version,
        release_stream: args.release_stream,
        snap_version: args.snap_version
    )

    send_snap_mail(
        release_stream: args.release_stream,
        release_version: args.release_version,
        snap_version: args.snap_version
    )
}

def generate_dependencies(args) {
    dir("satellite-dependencies") {
        git "https://${env.GIT_HOSTNAME}/${env.GIT_ORGANIZATION}/satellite-dependencies.git"
        sh "./satellite-dependencies.py --satellite ${args.satellite_version} --source ${args.source} > dependencies.json"
        archiveArtifacts allowEmptyArchive: true, artifacts: 'dependencies.json'
    }
}
