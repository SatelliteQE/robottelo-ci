def packages_to_build = null
def build_status = 'failed'

node('sat6-rhel7') {
    stage("Fetch git") {
        deleteDir()
        gitlab_clone_and_merge("satellite-packaging", build_type)
    }

    stage("Find packages to build") {
        if (project) {
            packages_to_build = project
        } else if (build_type == 'release') {
            merge_commit = find_merge_commit("${env.gitlabMergeRequestLastCommit}", "origin/${env.gitlabTargetBranch}")
            merge_info = sh(returnStdout: true, script: "git rev-list --parents -n 1 ${merge_commit}").split()
            // check if we got two parents, otherwise it's not a merge
            if (merge_info.length == 3) {
                changed_packages = sh(returnStdout: true, script: "git diff ${merge_info[1]}...${merge_info[2]} --name-only 'packages/*.spec' | cut -d'/' -f2 |sort -u").trim()
                packages_to_build = changed_packages.split().join(':')
            }
        } else if (build_type == 'scratch') {
            changed_packages = sh(returnStdout: true, script: "git diff ..origin/${env.gitlabTargetBranch} --name-only 'packages/*.spec' | cut -d'/' -f2 |sort -u").trim()
            packages_to_build = changed_packages.split().join(':')
        }
        if (!packages_to_build) {
            currentBuild.result = 'NOT_BUILT'
            updateGitlabCommitStatus state: 'canceled'
            error('No packages to build.')
        }
        update_build_description_from_packages(packages_to_build)
    }

    stage("Build packages") {
        try {

            kerberos_setup()

            gitlabCommitStatus(build_type) {
                runPlaybook {
                    ansibledir = '.'
                    inventory = 'package_manifest.yaml'
                    playbook = packaging_playbook
                    limit = packages_to_build
                    tags = 'wait,download'
                }
            }

            build_status = 'succeeded'

        } finally {

            kerberos_cleanup()

            update_build_description_from_packages(packages_to_build)

            if (build_type == 'release') {
                brew_status_comment(build_status)
            }

            archive "kojilogs/**"

            deleteDir()

        }
    }
}

def get_koji_tasks() {
    def tasks = []
    if(fileExists('kojilogs')) {
        tasks = sh(returnStdout: true, script: "ls kojilogs -1 |grep -o '[0-9]*\$'").trim().split()
    }
    return tasks
}

def brew_status_comment(build_status) {
    tasks = get_koji_tasks()
    comment = "build status: ${build_status}\n\nbrew:"
    for (String task: tasks) {
        comment += "\n * https://brewweb.engineering.redhat.com/brew/taskinfo?taskID=${task}"
    }
    addGitLabMRComment comment: comment
}

def update_build_description_from_packages(packages_to_build) {
    build_description = "${packages_to_build}"
    if(fileExists('kojilogs')) {
        build_description += ":"
        tasks = get_koji_tasks()
        for (String task: tasks) {
            build_description += " brew#<a href='https://brewweb.engineering.redhat.com/brew/taskinfo?taskID=${task}'>${task}</a>"
        }
    }
    currentBuild.description = build_description
}
