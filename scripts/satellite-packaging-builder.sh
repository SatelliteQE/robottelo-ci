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

mk_yum_repo() {
    local reponame="${1:?}"
    local repourl="${2:?}"
    local gpgcheck="${3:-0}"
    local enabled="${4:-1}"
    echo "[$reponame]"
    echo "name=\"$reponame\""
    echo "baseurl=\"$repourl\""
    echo "enabled=$enabled"
    echo "gpgcheck=$gpgcheck"
    echo "skip_if_unavailable=True"
}

symbol_str() {
    local str="${1?}"
    echo "$str" | tr -c '[:alnum:]-\n' '_'
}

mocktito_opts=()
if [[ -n "$SATELLITE_SERVER" ]]; then
    # if SATELLITE_SERVER is defined use is as source for build dependencies
    sat_http_server="http://${SATELLITE_SERVER#http*://}"
    SATELLITE_ORG="${SATELLITE_ORG:-Sat6-CI}" # Satellite 6 organisation to use
    PRODUCT="${PRODUCT:-Satellite6}"          # The product in Satellite to
                                              # store artefatcs in
    repo_base="$sat_http_server/pulp/repos/$SATELLITE_ORG/Library"
    for target in satellite-6.2.0-{,tfm-}rhel-{6,7}; do
        target_sym="$(symbol_str "$target")"
        repo_url="$repo_base/$target_sym/custom/$PRODUCT/$target_sym"
        yum_repo="$(mk_yum_repo "$target" "$repo_url")"
        mocktito_opts+=( --extra-yum-repos-for "$target" "$yum_repo" )
    done
fi

# run mocktito.py to patch tito configuration
python "$PYLIBSPATH/mocktito.py" "${mocktito_opts[@]}"

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
