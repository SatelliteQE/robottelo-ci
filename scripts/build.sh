#!/bin/bash -e
# build.sh - Build Satellite 6 packages
#
#   This script should be run from the root of the package's git repo
#
# Requirements:
# - tito
# - koji
# - brewkoji
# - mock
#
#TODO: Set a parameter for this
DIST='.el7'
OUTPUTDIR='build_results'
PYLIBSPATH="$(dirname "$0")/../lib/python"

if [[ -n "$WORKSPACE" ]]; then
    # if $WORKSPACE is set assume we are in Jenkins
    OUTPUTDIR="$WORKSPACE/build_results"
    PYLIBSPATH="$WORKSPACE/robotello-ci/lib/python"
    #TODO: parameterize this:
    PROJECT_PATH="foreman"
    cd "$PROJECT_PATH"
fi

mkdir -p "$OUTPUTDIR"
SRC_RPM="$(
    tito build \
        --offline \
        --srpm \
        --test \
        --dist="${DIST}" \
        --scl=ruby193 \
        --output="$OUTPUTDIR" \
    | sed -nre 's/^Wrote: (.*\.src\.rpm)$/\1/p'
)"

echo Tito built: "$SRC_RPM"

python "$PYLIBSPATH/mock_brew.py" \
    --resultdir="$OUTPUTDIR" \
    "$SRC_RPM"
