def gemset(name) {

    def base_name = "${JOB_NAME}-${BUILD_ID}"

    if (name) {
        base_name = base_name + '-' + name
    }

    base_name
}

def cleanup_rvm(name = '', ruby = '2.0') {
    withRVM(["rvm gemset delete ${gemset(name)} --force"], ruby)
}

def withRVM(commands, ruby = '2.0', name = '') {

    commands = commands.join("\n")
    echo commands

    sh """#!/bin/bash -l
        rvm use ruby-${ruby}@${gemset(name)} --create
        gem install bundler
        ${commands}
    """
}
