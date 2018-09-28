def packages_to_build = null
def build_status = 'failed'
def VERCMP_NEWER = 12
def VERCMP_OLDER = 11
def VERCMP_EQUAL = 0

node('sat6-build') {
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
                changed_packages = find_changed_packages("${merge_info[1]}...${merge_info[2]}")
                packages_to_build = changed_packages.split().join(' ')
            }
        } else if (build_type == 'scratch') {
            changed_packages = find_changed_packages("origin/${env.gitlabTargetBranch}")
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
                new_release = query_rpmspec("packages/${package_name}/*.spec", '%{RELEASE}')

                sh "git checkout origin/${env.gitlabTargetBranch}"
                if (fileExists("packages/${package_name}")) {
                    old_version = query_rpmspec("packages/${package_name}/*.spec", '%{VERSION}')
                    old_release = query_rpmspec("packages/${package_name}/*.spec", '%{RELEASE}')

                    sh "git checkout -"

                    compare_version = sh(
                      script: "rpmdev-vercmp ${old_version} ${new_version}",
                      returnStatus: true
                    )

                    compare_release = sh(
                      script: "rpmdev-vercmp ${old_release} ${new_release}",
                      returnStatus: true
                    )

                    compare_new_to_one = sh(
                      script: "rpmdev-vercmp 1 ${new_release}",
                      returnStatus: true
                    )

                    if (compare_version != VERCMP_EQUAL && (compare_new_to_one == VERCMP_OLDER || compare_new_to_one == VERCMP_EQUAL)) {
                        // new version, release back to 1
                        version_status = 'success'
                        release_status = 'success'
                    } else if (compare_version != VERCMP_EQUAL && compare_new_to_one == VERCMP_NEWER) {
                        // new version, but release was not reset
                        version_status = 'success'
                    } else if (compare_version == VERCMP_EQUAL && compare_release == VERCMP_NEWER) {
                        // old version, release was bumped
                        version_status = 'success'
                        release_status = 'success'
                    }
                } else {
                    sh "git checkout -"

                    version_status = 'success'
                    release_status = 'success'
                }

                updateGitlabCommitStatus name: "${package_name}_version", state: version_status
                updateGitlabCommitStatus name: "${package_name}_release", state: release_status
            }
        }
    }

    stage("Check brew builds") {
        if (build_type == 'scratch') {
            def packages = packages_to_build.split(' ')

            for (int i = 0; i < packages.size(); i++) {
                package_name = packages[i]

                version = query_rpmspec("packages/${package_name}/*.spec", '%{VERSION}')
                release = query_rpmspec("packages/${package_name}/*.spec", '%{RELEASE}')

                brew_buildinfo = sh(
                  script: "brew buildinfo ${package_name}-${version}-${release}.el7sat",
                  returnStdout: true
                ).trim()

                if(brew_buildinfo.contains('No such build')) {
                  updateGitlabCommitStatus name: "${package_name}_brew_build", state: "success"
                } else {
                  updateGitlabCommitStatus name: "${package_name}_brew_build", state: "failed"
                }
            }
        }
    }

    stage("Build packages") {
        def krbcc
        try {

            krbcc = kerberos_setup()

            setup_obal()

            gitlabCommitStatus(build_type) {
                withEnv(["KRB5CCNAME=${krbcc}"]) {
                    obal(
                        action: build_type,
                        extraVars: ['build_package_download_logs': 'True'],
                        packages: packages_to_build
                    )
                }
            }

            build_status = 'succeeded'

            if (build_type == 'release') {
                mark_bugs_built(build_status, packages_to_build, package_version, tool_belt_config)
            }

        } finally {

            update_build_description_from_packages(packages_to_build)

            kerberos_cleanup(krbcc)

            if (build_type == 'release') {
                brew_status_comment(build_status)
            }

            archive "kojilogs/**"
            deleteDir()

        }
    }
}

def mark_bugs_built(build_status, packages_to_build, package_version, tool_belt_config) {
    def packages = packages_to_build.split(' ')
    def comment = get_brew_comment(build_status)

    for (int i = 0; i < packages.size(); i++) {
        package_name = packages[i]
        rpm = query_rpmspec("packages/${package_name}/*.spec", "${package_name}-%{VERSION}-%{RELEASE}")
        ids = sh(returnStdout: true, script: "rpmspec -q --srpm --queryformat=%{CHANGELOGTEXT} packages/${package_name}/*.spec |grep '^- BZ' | sed -E 's/^- BZ[ #]+?([0-9]+).*/\\1/'").trim()

        if (ids.size() > 0) {
            ids = ids.split("\n").join(' --bug ')

            withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'bugzilla-credentials', passwordVariable: 'BZ_PASSWORD', usernameVariable: 'BZ_USERNAME']]) {

                toolBelt(
                    command: 'bugzilla set-fixed-in',
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
                    command: 'bugzilla set-build-state',
                    config: tool_belt_config,
                    options: [
                        "--bz-username ${env.BZ_USERNAME}",
                        "--bz-password ${env.BZ_PASSWORD}",
                        "--state rpm_built",
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

    dir('tool_belt') {
        deleteDir()
    }
}

def find_changed_packages(diff_range) {
    return sh(returnStdout: true, script: "git diff ${diff_range} --name-only --diff-filter=d -- 'packages/**.spec' | cut -d'/' -f2 |sort -u").trim()
}

def get_brew_comment(build_status) {
    def tasks = get_koji_tasks()
    def comment = "build status: ${build_status}\n\nbrew:"
    for (String task: tasks) {
        taskinfo = sh(returnStdout: true, script: "brew taskinfo -v ${task}").trim()
        taskinfo_yaml = readYaml text: taskinfo
        build_status = taskinfo_yaml["State"]
        build_package = taskinfo_yaml["Request Parameters"]["Source"]
        build_package = build_package.split('/')[-1]
        build_package = build_package.split('\\?')[0]
        comment += "\n * ${build_package}: ${build_status} - https://brewweb.engineering.redhat.com/brew/taskinfo?taskID=${task}"
    }
    return comment
}

def get_koji_tasks() {
    def tasks = []
    if(fileExists('kojilogs')) {
        parent_tasks = get_koji_tasks_from_folder('kojilogs')
        child_tasks = get_koji_tasks_from_folder('kojilogs/*')
        if (parent_tasks.size() == child_tasks.size()) {
            tasks = child_tasks
        } else {
            tasks = parent_tasks
        }
    }
    return tasks
}

def get_koji_tasks_from_folder(folder) {
   return sh(returnStdout: true, script: "ls ${folder} -1 |grep -o '[0-9]*\$'").trim().split()
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
    result = sh(returnStdout: true, script: "rpmspec -q --srpm --undefine=dist --undefine=foremandist --queryformat=${queryformat} ${specfile}").trim()
    return result
}
