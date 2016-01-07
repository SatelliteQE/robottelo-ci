#!/bin/bash -ex
# satellite6-builder.sh - Build Satellite 6 packages
#
#   This script should be run from the root of the package's git repo
#
# Requirements:
# - tito
# - koji
# - brewkoji
# - mock (Please ensure the user running the script is in the 'mock' group)
#
#TODO: Set a parameter for this
DIST='.el7'
OUTPUTDIR='build_results'
PYLIBSPATH="$(dirname "$0")/../lib/python"

if [[ -n "$WORKSPACE" ]]; then
    # if $WORKSPACE is set assume we are in Jenkins
    OUTPUTDIR="$WORKSPACE/build_results"
    PYLIBSPATH="$WORKSPACE/robotello-ci/lib/python"
fi

if [[ -n "$PROJECT_PATH" ]]; then
    cd "$PROJECT_PATH"
fi

TITO_RELEASE="${TITO_RELEASE:-ruby193-git-sat}"

PYTHONPATH="$PYLIBSPATH"
export PYTHONPATH

mkdir -p "$OUTPUTDIR"
find "$OUTPUTDIR" -mindepth 1 -maxdepth 1 -print0 \
    | xargs -0 -r -P0 rm -rf

# run mocktito.py to patch tito configuration
python "$PYLIBSPATH/mocktito.py"

# do the build with tito
tito release "$TITO_RELEASE" --test --offline --output="$OUTPUTDIR"
