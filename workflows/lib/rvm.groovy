def gemset() {
    "${JOB_NAME}-${BUILD_ID}"
}

def cleanup_rvm() {
    withRVM(["rvm gemset delete ${gemset()} --force"])
}

def withRVM(commands, ruby = '2.0') {

    commands = commands.join("\n")
    echo commands

    sh """#!/bin/bash -l
        rvm use ruby-${ruby}@${gemset()} --create
        ${commands}
    """
}
