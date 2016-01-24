#!/bin/bash -ex
# satellite6-builder.sh - Build Satellite 6 packages
#
#   This script should be run from the root of the satellite-packaging git repo
#   For the script to work the COLLECTION, PACKAGE and gitlabSourceBranch
#   environment varaibles must be set
#
# Requirements:
# - tito
# - koji
# - brewkoji
# - mock (Please ensure the user running the script is in the 'mock' group)
# - scl-utils-build (if building an scl project)
# - rpmdevtools (for spectool)
#
OUTPUTDIR="$PWD/build_results"
PYLIBSPATH="$(dirname "$0")/../lib/python"

if [[ -n "$WORKSPACE" ]]; then
    # if $WORKSPACE is set assume we are in Jenkins
    OUTPUTDIR="$WORKSPACE/build_results"
    PYLIBSPATH="$WORKSPACE/robotello-ci/lib/python"
fi

if [[ -n "$PROJECT_PATH" ]]; then
    cd "$PROJECT_PATH"
fi

TITO_RELEASE="${TITO_RELEASE:-dist-git-sat}"
COLLECTION="${COLLECTION:?}"
PACKAGE="${PACKAGE:?}"
gitlabSourceBranch="${gitlabSourceBranch:?}"

PYTHONPATH="$PYLIBSPATH"
export PYTHONPATH

mkdir -p "$OUTPUTDIR"
find "$OUTPUTDIR" -mindepth 1 -maxdepth 1 -print0 \
    | xargs -0 -r -P0 rm -rf

# run mocktito.py to patch tito configuration
python "$PYLIBSPATH/mocktito.py"

# init git annex to get source archives
git checkout "$gitlabSourceBranch"
git config user.email "jenkins@$(hostname -f)"
git config user.name "Jenkins"
git annex init

# setup git annex package sources
cd "$COLLECTION"
./setup_sources.sh "$PACKAGE"

# do the build with tito
cd "$PACKAGE"
tito release "$TITO_RELEASE" --test --offline --output="$OUTPUTDIR"
