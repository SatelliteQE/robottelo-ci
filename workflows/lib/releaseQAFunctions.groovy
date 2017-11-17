// Library Methods

def promoteContentView(body) {

    def config = [:]
    body.resolveStrategy = Closure.DELEGATE_FIRST
    body.delegate = config
    body()

    runPlaybook {
      playbook = 'playbooks/promote_content_view.yml'
      extraVars = [
          'content_view_name': config.content_view,
          'organization': config.organization,
          'to_lifecycle_environment': config.to_lifecycle_environment,
          'from_lifecycle_environment': config.from_lifecycle_environment,
      ]
    }
}

def findContentView(body) {

    def config = [:]
    body.resolveStrategy = Closure.DELEGATE_FIRST
    body.delegate = config
    body()

    withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'artefact-satellite-credentials', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME']]) {

        def cmd = [
          "/bin/bash --login -c",
          "'rvm system && ",
          "hammer --output json --username \"${env.USERNAME}\" --password \"${env.PASSWORD}\" --server ${env.SATELLITE_SERVER}",
          "content-view version list",
          "--organization \"${config.organization}\"",
          "--environment \"${config.lifecycle_environment}\"",
          "--content-view \"${config.content_view}\"'"
        ]

        sh "${cmd.join(' ')} > versions.json"

        def versions = readFile "versions.json"
        versions = new JsonSlurper().parseText(versions)

        if (versions.size() == 0) {
            return null;
        } else {
            return versions.first()['ID'];
        }
    }
}

def computePackageDifference(body) {

    def config = [:]
    body.resolveStrategy = Closure.DELEGATE_FIRST
    body.delegate = config
    body()

    withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'artefact-satellite-credentials', passwordVariable: 'SATELLITE_PASSWORD', usernameVariable: 'SATELLITE_USERNAME']]) {

        dir('tool_belt') {

            setup_toolbelt()
            def archive_file = 'package_report.yaml'

            def cmd = [
                "bundle exec",
                "./tools.rb release compare-content-view",
                "--server '${env.SATELLITE_SERVER}'",
                "--username '${env.SATELLITE_USERNAME}' --password '${env.SATELLITE_PASSWORD}'",
                "--organization '${config.organization}'",
                "--content-view '${config.content_view}'",
                "--from-environment '${config.from_environment}'",
                "--to-environment '${config.to_environment}'",
                "--output '${archive_file}'"
            ]

            sh "${cmd.join(' ')}"
            archive archive_file

        }
    }

}

def createLifecycleEnvironment(body) {

    def config = [:]
    body.resolveStrategy = Closure.DELEGATE_FIRST
    body.delegate = config
    body()

    withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'artefact-satellite-credentials', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME']]) {

        def cmd = [
            "/bin/bash --login -c",
            "'rvm system && ",
            "hammer --output json",
            "--username \"${env.USERNAME}\"",
            "--password \"${env.PASSWORD}\"",
            "--server ${env.SATELLITE_SERVER}",
            "lifecycle-environment create",
            "--organization \"${config.organization}\"",
            "--name \"${config.name}\"",
            "--prior \"${config.prior}\"'"
        ]

        sh "${cmd.join(' ')}"
    }
}

def compareContentViews(body) {

    def config = [:]
    body.resolveStrategy = Closure.DELEGATE_FIRST
    body.delegate = config
    body()

    def versionInTest = findContentView {
      organization = config.organization
      content_view = config.content_view
      lifecycle_environment = config.from_lifecycle_environment
    }

    def versionInQA = findContentView {
      organization = config.organization
      content_view = config.content_view
      lifecycle_environment = config.to_lifecycle_environment
    }

    echo versionInTest.toString()
    echo versionInQA.toString()

    if (versionInTest != versionInQA && versionInTest != null) {

        computePackageDifference {
          organization = config.organization
          content_view = config.content_view
          from_environment = config.from_lifecycle_environment
          to_environment = config.to_lifecycle_environment
        }

    } else {

        echo "Version already promoted, no package changes calculated"

    }
}
