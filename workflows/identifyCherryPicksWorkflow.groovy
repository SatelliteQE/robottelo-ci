def version = '6.2.0'
def milestone = '6.2.15'

node('sat6-build') {

    stage("Setup ToolBelt") {
        toolBelt(
            command: 'setup-environment',
            options: [
                "--gitlab-username jenkins",
                "--version ${version}"
            ]
        )
    }

    stage("Identify Cherry Picks") {

        withCredentials([
            [$class: 'UsernamePasswordMultiBinding', credentialsId: 'bugzilla-credentials', passwordVariable: 'BZ_PASSWORD', usernameVariable: 'BZ_USERNAME'],
            [$class: 'UsernamePasswordMultiBinding', credentialsId: 'octokit_token', passwordVariable: 'OCTOKIT_ACCESS_TOKEN', usernameVariable: 'OCTOKIT_TOKEN']]) {

                toolBelt(
                    command: 'cherry-picks report',
                    options: [
                        "--bz-username ${env.BZ_USERNAME}",
                        "--bz-password ${env.BZ_PASSWORD}",
                        "--version ${version}",
                        "--milestone ${milestone}",
                        "--no-update-repos"
                    ],
                    archive_file: "releases/${version}/bugzillas"
                )

          }
    }

}
