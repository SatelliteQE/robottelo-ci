def packages_to_build = null
def build_status = 'failed'

node('sat6-rhel7') {
    stage("Fetch git") {
        deleteDir()
        gitlab_clone_and_merge("${packaging_repo_project}/${packaging_repo}", build_type)
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
                packages_to_build = changed_packages.split().join(' ')
            }
        } else if (build_type == 'scratch') {
            changed_packages = sh(returnStdout: true, script: "git diff ..origin/${env.gitlabTargetBranch} --name-only 'packages/*.spec' | cut -d'/' -f2 |sort -u").trim()
            packages_to_build = changed_packages.split().join(' ')
        }
        if (!packages_to_build) {
            currentBuild.result = 'NOT_BUILT'
            updateGitlabCommitStatus name: build_type, state: 'canceled'
            error('No packages to build.')
        }
        update_build_description_from_packages(packages_to_build)
    }

    stage("Verify version and release"){
        if (build_type == 'scratch') {
            def packages = packages_to_build.split(' ')

            for (int i = 0; i < packages.size(); i++) {
                package_name = packages[i]
                version_status = 'failed'
                release_status = 'failed'

                new_version = query_rpmspec("packages/${package_name}/*.spec", '%{VERSION}')
                new_release = query_rpmspec("packages/${package_name}/*.spec", '%{RELEASE}').toFloat()

                sh "git checkout origin/${env.gitlabTargetBranch}"
                old_version = query_rpmspec("packages/${package_name}/*.spec", '%{VERSION}')
                old_release = query_rpmspec("packages/${package_name}/*.spec", '%{RELEASE}').toFloat()
                sh "git checkout -"

                if (new_version != old_version && new_release == 1) {
                    // new version, release back to 1
                    version_status = 'success'
                    release_status = 'success'
                } else if (new_version != old_version && new_release != 1) {
                    // new version, but release was not reset
                    version_status = 'success'
                } else if (new_version == old_version && new_release > old_release) {
                    // old version, release was bumped
                    version_status = 'success'
                    release_status = 'success'
                }

                updateGitlabCommitStatus name: "${package_name}_version", state: version_status
                updateGitlabCommitStatus name: "${package_name}_release", state: release_status
            }
        }
    }

    stage("Build packages") {
        try {

            kerberos_setup()

            gitlabCommitStatus(build_type) {
                obal {
                    action = build_type
                    extraVars = ['build_package_download_logs': 'True']
                    packages = packages_to_build
                }
            }

            build_status = 'succeeded'

        } finally {

            kerberos_cleanup()

            update_build_description_from_packages(packages_to_build)

            if (build_type == 'release') {
                mark_bugs_built(build_status, packages_to_build, package_version)
                brew_status_comment(build_status)
            }

            archive "kojilogs/**"

            deleteDir()

        }
    }
}

def mark_bugs_built(build_status, packages_to_build, package_version) {
    def packages = packages_to_build.split(' ')
    def comment = get_brew_comment(build_status)

    dir('tool_belt') {
        setup_toolbelt()
    }

    for (int i = 0; i < packages.size(); i++) {
        package_name = packages[i]
        rpm = query_rpmspec("packages/${package_name}/*.spec", "${package_name}-%{VERSION}-%{RELEASE}")
        ids = sh(returnStdout: true, script: "rpmspec -q --srpm --queryformat=%{CHANGELOGTEXT} packages/${package_name}/*.spec |grep '^- BZ' | sed -E 's/^- BZ[ #]+?([0-9]+).*/\\1/'").trim()

        dir('tool_belt') {
            if (ids.size() > 0) {
                ids = ids.split("\n").join(' --bug ')

                withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'bugzilla-credentials', passwordVariable: 'BZ_PASSWORD', usernameVariable: 'BZ_USERNAME']]) {

                    toolBelt(
                        command: 'release set-fixed-in',
                        config: tool_belt_config,
                        options: [
                            "--bz-username ${env.BZ_USERNAME}",
                            "--bz-password ${env.BZ_PASSWORD}",
                            "--rpm ${rpm}",
                            "--bug ${ids}",
                            "--version ${package_version}"
                        ]
                    )

                    toolBelt(
                        command: 'release set-build-state',
                        config: tool_belt_config,
                        options: [
                            "--bz-username ${env.BZ_USERNAME}",
                            "--bz-password ${env.BZ_PASSWORD}",
                            "--state rpm_build",
                            "--bug ${ids}",
                            "--version ${package_version}"
                        ]
                    )

                    toolBelt(
                        command: 'bugzilla add-comment',
                        config: tool_belt_config,
                        options: [
                            "--bz-username ${env.BZ_USERNAME}",
                            "--bz-password ${env.BZ_PASSWORD}",
                            "--bug ${ids}",
                            "--version ${package_version}",
                            "--comment '${comment}'"
                        ]
                    )
                }
            }
        }
    }

    dir('tool_belt') {
        deleteDir()
    }
}

def get_brew_comment(build_status) {
    def tasks = get_koji_tasks()
    def comment = "build status: ${build_status}\n\nbrew:"
    for (String task: tasks) {
        comment += "\n * https://brewweb.engineering.redhat.com/brew/taskinfo?taskID=${task}"
    }
    return comment
}

def get_koji_tasks() {
    def tasks = []
    if(fileExists('kojilogs')) {
        tasks = sh(returnStdout: true, script: "ls kojilogs -1 |grep -o '[0-9]*\$'").trim().split()
    }
    return tasks
}

def brew_status_comment(build_status) {
    def comment = get_brew_comment(build_status)
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

def query_rpmspec(specfile, queryformat) {
    result = sh(returnStdout: true, script: "rpmspec -q --srpm --undefine=dist --queryformat=${queryformat} ${specfile}").trim()
    return result
}
