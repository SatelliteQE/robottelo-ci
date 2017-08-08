def packages_to_build = null

node('sat6-rhel7') {
    stage("Fetch git") {
        deleteDir()

        git url: "https://$GIT_HOSTNAME/$GIT_ORGANIZATION/satellite-packaging.git", branch: targetBranch

        if (sourceRepoName) {
            sh "git remote add pr https://$GIT_HOSTNAME/${sourceRepoName}.git"
            sh "git fetch pr"
            sh "git merge pr/${sourceBranch}"
        }
    }

    stage("Find packages to build") {
        if (project) {
            packages_to_build = project
        } else {
            changed_packages = sh(returnStdout: true, script: "git diff ..origin/${targetBranch} --name-only packages/ | cut -d'/' -f2 |sort -u").trim()
            packages_to_build = changed_packages.split().join(':')
        }
        if (!packages_to_build) {
            currentBuild.result = 'NOT_BUILT'
            error('No packages to build.')
        }
        update_build_description_from_packages(packages_to_build)
    }

    stage("Build packages") {
        try {

            kerberos_setup()

            runPlaybook {
                ansibledir = '.'
                inventory = 'package_manifest.yaml'
                playbook = packaging_playbook
                limit = packages_to_build
                tags = 'wait,download'
            }

        } finally {

            kerberos_cleanup()

            update_build_description_from_packages(packages_to_build)

            archive "kojilogs/**"

            deleteDir()

        }
    }
}

def update_build_description_from_packages(packages_to_build) {
    build_description = "${packages_to_build}"
    if(fileExists('kojilogs')) {
        build_description += ":"
        tasks = sh(returnStdout: true, script: "ls kojilogs -1 |grep -o '[0-9]*\$'").trim().split()
        for (String task: tasks) {
            build_description += " brew#<a href='https://brewweb.engineering.redhat.com/brew/taskinfo?taskID=${task}'>${task}</a>"
        }
    }
    currentBuild.description = build_description
}
