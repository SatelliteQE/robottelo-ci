#!/bin/bash -e
# uploat-built-packages.sh - Upload packages to a satellite 6 instance and
#                            create the repositories, content views and
#                            content view versions needed to make them
#                            available for consumption via the 'Library'
#                            environment
#
# This script expects to be run from Jenkins, and have quite a few environment
# variables pre-configured as described below.
# The host running this script need to have hammer (rubygem-hammer_cli_katello
# package) installed.

WORKSPACE="${WORKSPACE:?}"                # path to a Jenkins workspace
SATELLITE_SERVER="${SATELLITE_SERVER:?}"  # Satellite 6 server URL
SATELLITE_USER="${SATELLITE_USER:?}"      # Satellite 6 user (should be able to
                                          # upload packages and create content
                                          # views, etc.)
SATELLITE_PWD="${SATELLITE_PWD:?}"        # Satellite 6 user password
SATELLITE_ORG="${SATELLITE_ORG:-Sat6-CI}" # Satellite 6 organisation to use
                                          # (must already exist on the server)
PACKAGE="${PACKAGE:?}"                    # the name of the (source) package
                                          # for which we're uploading built
                                          # artefacts
PRODUCT="${PRODUCT:-Satellite6}"          # The product in Satellite to store
                                          # artefatcs in
OUTPUTDIR="$WORKSPACE/build_results"      # we expect this to already exist
HAMMER='/usr/bin/hammer'                  # we expect hammer to be there

main() {
    verify_hammer

    [[ -d "$OUTPUTDIR" ]] || die 'Cannot find build output directory'
    # build script should've created $OUTPUTDIR/$PACKAGE-<version>
    local package_dir="$(echo "$OUTPUTDIR/$PACKAGE-"*)"
    [[ -d "$package_dir" ]] || die 'Cannot find built package directory'

    verify product "$SATELLITE_ORG" "$PRODUCT"

    # build script should create directory per build target
    find "$package_dir" -mindepth 1 -maxdepth 1 -type d -printf "%P\n" \
    | while read target; do
        echo "Found build target: '$target'"
        local version="$(find_version_from_rpms "$package_dir/$target")"
        if [[ -n "$version" ]]; then
            echo "Found package version in target: $version"
        else
            echo 'Did not find package version in target'
            echo 'Are there any RPMs here?'
            continue
        fi
        verify repository "$SATELLITE_ORG" "$target" \
            --product="$PRODUCT" --content-type=yum
        find "$package_dir/$target" -mindepth 1 -maxdepth 1 \
            -type f -name '*.rpm' ! -name "*.src.rpm" \
        | while read artefact; do
            upload_rpm "$SATELLITE_ORG" "$PRODUCT" "$target" "$artefact"
        done
        verify content-view "$SATELLITE_ORG" "$target"
        add_repo_to_cv "$SATELLITE_ORG" "$target" "$PRODUCT" "$target"
        publish_cv "$SATELLITE_ORG" "$target" "$version"
    done
}

verify() {
    # check for Satellite 6 object and create if not there
    local otype="${1:?}" # Object type (product/repo/content-view/etc.)
    local org="${2:?}"   # Oraganization
    local name="${3:?}"  # Object name
    shift 3 # All other arguemts are passed to hammer

    echo "Verifying $otype: '$name' at '$org'"
    hammer "$otype" list --organization-label="$org" --name="$name" "$@" \
        | grep -qE '.+' \
        || hammer "$otype" create \
            --organization-label="$org" \
            --name="$name" "$@"
}

find_version_from_rpms() {
    # Find package version of first RPM file in given path
    local rpmdir="${1:?}"

    find "$rpmdir" -type f -name "*.rpm" ! -name "*.src.rpm" \
        | head -1 \
        | xargs -rn1 rpm -q --qf "%{V}-%{R}\n" -p
}

upload_rpm() {
    # upload rpm package to Satellite repository
    local org="${1:?}"     # Oraganization
    local product="${2:?}" # Product name
    local repo="${3:?}"    # repository
    local package="${4:?}" # package file path

    hammer repository upload-content \
        --organization-label="$org" \
        --product="$product" \
        --name="$repo" \
        --path="$package"
}

add_repo_to_cv() {
    # add repo to content view (idempotent)
    local org="${1:?}"          # Oraganization
    local content_view="${2:?}" # content view name
    local product="${3:?}"      # Product name
    local repo="${4:?}"         # repository

    hammer content-view add-repository \
        --organization-label="$org" \
        --name="$content_view" \
        --product="$product" \
        --repository="$repo"
}

publish_cv() {
    # Publish a content view
    local org="${1:?}"          # Oraganization
    local content_view="${2:?}" # content view name
    local version_desc="${3:?}" # version description

    hammer content-view publish \
        --organization-label="$org" \
        --name="$content_view" \
        --description="$version_desc"
}

verify_hammer() {
    [[ -x "$HAMMER" ]] || die "Cannot find hammer at $HAMMER"
}

hammer() {
    "$HAMMER" \
        --server="$SATELLITE_SERVER" \
        --username="$SATELLITE_USER" \
        --password="$SATELLITE_PWD" \
        --output=base \
        "$@"
}

die() {
    echo "$@" 1>&2
    exit 1
}

main "$@"
