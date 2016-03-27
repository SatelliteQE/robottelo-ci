#!/bin/bash -e
# mk-rhev-template.sh - Create oVirt template out of a guest image in Brew
#
set -e -o pipefail

# Environment variables that affect this script are listed below
if [[ -n "$WORKSPACE" ]]; then
    # if $WORKSPACE is set assume we are in Jenkins
    IMAGE_DATA_DIR="$WORKSPACE/robotello-ci/imagebuild"
else
    IMAGE_DATA_DIR="$(dirname "$0")/../imagebuild"
    WORKSPACE="$PWD"
fi
RESULT_DIR="$WORKSPACE/build_results"

KOJI_TOPURL="${KOJI_TOPURL:-http://download.devel.redhat.com/brewroot}"
KOJI_PROFILE="${KOJI_PROFILE:-brew}"

IMAGE_KOJI_TAG="${IMAGE_KOJI_TAG:-guest-rhel-7.2-candidate}"
IMAGE_KOJI_PKG="${IMAGE_KOJI_PKG:-rhel-guest-image}"

REGISTRATION_USER="${REGISTRATION_USER:?Must specify REGISTRATION_USER}"
REGISTRATION_PWD="${REGISTRATION_PWD:?Must specify REGISTRATION_PWD}"
REGISTRATION_DATA="${REGISTRATION_DATA:-rhel.7}"

TEMPLATE_DISK_SIZE="${TEMPLATE_DISK_SIZE:-20G}"
TEMPLATE_ROOT_DEVICE="${TEMPLATE_ROOT_DEVICE:-/dev/sda1}"

PUPPET_REPO="${PUPPET_REPO:-https://github.com/SatelliteQE/puppet-robottelo_slave.git}"
PUPPET_BRANCE="${PUPPET_BRANCE:-master}"

# The following optiona variables can be used to make the generated
# image join a Jenkins swarm
# JENKINS_URL
# JENKINS_USER
# JENKINS_PASS

main() {
    local image_name image_file image_disk_dev template_name
    image_name="$(check_latest_image)"
    template_name="sat-slave-${image_name}"
    echo "Dowloading image: $image_name from brew"
    image_file="$(download_image "$image_name")"
    echo "Preparing disk for new template"
    image_disk_dev="$(image_to_disk "$template_name" "$image_file")"
    echo "Customizing image"
    customize_image "$image_name" "$template_name" "$image_disk_dev"
    echo "Done createing image: '$image_disk_dev'"
}

check_latest_image() {
    koji -p "$KOJI_PROFILE" -q \
        latest-build --type=image "$IMAGE_KOJI_TAG" "$IMAGE_KOJI_PKG" \
        | awk '{ print $1 }'
}

download_image() {
    local image_name="${1:?}"
    local image_file="${WORKSPACE}/${image_name}.x86_64.qcow2"
    local image_url
    image_url="$(koji_image_url "$image_name")"
    curl -f -s -S -L -C - "${image_url}" -o "$image_file"
    echo "$image_file"
}

image_to_disk() {
    local disk_name="${1:?}"
    local image_file="${2:?}"
    local image_size
    mkdir -p "$RESULT_DIR"
    local disk_dev="${RESULT_DIR}/${disk_name}.qcow2"
    qemu-img create -q -f qcow2 -o preallocation=metadata "$disk_dev" \
        "$TEMPLATE_DISK_SIZE" 1>&2 \
    || return $?
    virt-resize -q --expand "$TEMPLATE_ROOT_DEVICE" "$image_file" \
        "$disk_dev" 1>&2 \
    || return $?
    echo "$disk_dev"
}

customize_image() {
    local image_name="${1:?}"
    local template_name="${2:?}"
    local target_image="${3:?}"

    local auto_sub_script="$IMAGE_DATA_DIR/auto-subscriber.bash"
    local auto_sub_tgt='/usr/local/sbin/auto_subscriber.bash'
    local auto_sub_conf="$IMAGE_DATA_DIR/${REGISTRATION_DATA}.regdata"
    local auto_sub_ctgt='/etc/sysconfig/auto_subscriber.conf'
    local auto_sub_content="$(printf "%s\n" \
        REGISTRATION_USER="'$REGISTRATION_USER'" \
        REGISTRATION_PWD="'$REGISTRATION_PWD'" \
        "$(cat "$auto_sub_conf")" \
    )"
    local puppet_tgt='/etc/puppet/local'

    local template_facts="$(printf "%s\n" \
        os_source_image="$image_name" \
        os_source_template="$template_name" \
    )"
    local image_customization=(
        --upload "$auto_sub_script":"$auto_sub_tgt"
        --chmod 0700:"$auto_sub_tgt"
        --write "$auto_sub_ctgt":"$auto_sub_content"
        --run-command "$auto_sub_tgt --keep-config"
        --install puppet
        --mkdir "/etc/facter/facts.d"
        --write "/etc/facter/facts.d/imageid.txt:'$template_facts'"
        --install git
        --run-command
            ":| git clone '$PUPPET_REPO' -b '$PUPPET_BRANCE' '$puppet_tgt'"
        --run-command "subscription-manager clean"
        --firstboot-command "$auto_sub_tgt"
    )
    if [[ -n "$IMAGE_ROOT_PWD" ]]; then
        local rootpwd="password:$IMAGE_ROOT_PWD"
    else
        echo "WARNING: IMAGE_ROOT_PWD not set, using a random password" 1>&2
        local rootpwd="random"
    fi
    if [[ -n "$JENKINS_URL" ]]; then
        local apply_params=(
            --auto-cloud-swarm
            --jenkins="$JENKINS_URL"
            --jenkins-user="$JENKINS_USER"
            --jenkins-pwd="$JENKINS_PASS"
        )
        local apply_params_escaped="$(printf " '%s'" "${apply_params[@]}")"
    else
        echo "WARNING: JENKINS_URL not set, host will not be a swarm slave" 1>&2
        local apply_params_escaped='--brew'
    fi
    # We need to crate a cript to run apply so the Jenkins password does
    # not get leaked to the Jenkins log
    local apply_script="$(mktemp -p "$WORKSPACE")"
    echo "cd '$puppet_tgt' && HOME=/root ./apply.sh ${apply_params_escaped[*]}" \
        > "$apply_script"
    image_customization+=(
        --write '/etc/sudoers.d/root_notty':$'Defaults:root !requiretty\n'
        --firstboot "$apply_script"
        --root-password "$rootpwd"
        --edit '/usr/lib/systemd/system/rhel-autorelabel.service: $_ = "" if /StandardInput=tty/'
        --selinux-relabel
    )

    virt-customize -a "$target_image" "${image_customization[@]}"
    local result=$?
    rm "$apply_script"
    return $result
}

disk_to_template() {
    local disk_name="${1:?}"
    local mk_template=do.ovirt.template.create_from_disk
    dofab -u root -H "$BUILDER_HOST" --hide=user,warnings \
        do.ovirt.vm.host_remove_disk:disk_name="$disk_name" \
    || return $?
    dofab -u root -H "$BUILDER_HOST" \
        do.ovirt.template.create_from_disk:"$(fabprm \
            disk_query=name\\="$disk_name" \
            cluster_query=name\\="$TARGET_CLUSTER" \
            networks="$TARGET_NETWORKS" \
            show=name,headers=no \
        )" \
    || return $?
}

koji_image_url() {
    local image_name="${1:?}"
    echo "${KOJI_TOPURL}/$(
        koji -p "$KOJI_PROFILE" buildinfo "$image_name" \
        | sed -nre 's#^/mnt/redhat/brewroot/(.*.x86_64.qcow2)$#\1#p'
    )"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
else
    # We need this to ensure set -x does not blow up the shell when script is
    # sourced
    set +e
fi
