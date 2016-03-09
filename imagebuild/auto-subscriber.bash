#!/bin/bash -e
# slave-subscribe-channels.sh - Subscribe to needed Red Hat channels for slave
#
CONF_FILE='/etc/sysconfig/auto_subscriber.conf'

main() {
    local -A config
    if ! load_configuration "$@"; then
        echo 'No configuration file found, exiting'
        return 0
    fi
    if [[ -n "$REGISTRATION_USER" ]]; then
        echo 'Registering host'
        setup_registration "$REGISTRATION_USER" "$REGISTRATION_PWD" \
        || die -1 'Falied to register system'
    else
        echo 'No host registration credentials in conf file, skipping'
    fi
    if [[ -n "$NEEDED_SUBSCRIPTION" ]]; then
        echo 'Setting up subscriptions'
        setup_subscription "$NEEDED_SUBSCRIPTION" \
            || die -2 'Failed to setup system subscription'
    else
        echo 'No subscription name in conf file, skipping'
    fi
    if [[ "${#NEEDED_REPOS[@]}" -gt 0 ]]; then
        echo 'Configuring yum repositories'
        setup_repos "${NEEDED_REPOS[@]}" \
            || die -3 'Failed to setup YUM repositories'
    else
        echo 'No needed repos listed in conf file, skipping'
    fi
    clean_configuration "$@"
}

load_configuration() {
    unset REGISTRATION_USER REGISTRATION_PWD NEEDED_SUBSCRIPTION NEEDED_REPOS
    [[ -f "$CONF_FILE" ]] || return 1
    source "$CONF_FILE" || die -11 "Failed to read $CONF_FILE"
}

clean_configuration() {
    if [[ "$1" != '--keep-config' ]]; then
        rm -f "$CONF_FILE" || echo "Failed to remove $CONF_FILE" 1>&2
    fi
}

setup_registration() {
    local user="${1:?}"
    local pass="${2:?}"
    subscription-manager register --username="$user" --password="$pass"
}

setup_subscription() {
    local needed_subscription="${1:?}"
    local pool_id
    subscription_exists "$needed_subscription" && return
    pool_id="$(get_subscription_pool_id "$needed_subscription")" \
        || return 1
    subscription-manager-log attach --pool="$pool_id" \
        || return 2
}

setup_repos() {
    local needed_repos="$(printf "%s\n" "$@" | sort -u)"
    local existing_repos
    existing_repos="$(
        subscription-manager repos --list-enabled \
            | sed -nre 's/^Repo ID:\s+(.*)\s*$/\1/p' \
            | sort -u
    )"
    # Remove repos that are in existing but not in needed
    disable_repo_params="$(
        comm -13 <(echo "$needed_repos") <(echo "$existing_repos") \
        | xargs -r -d '\n' printf '--disable="%s"\n'
    )"
    # Enable repos that we need and we havn't already
    enable_repo_params="$(
        comm -23 <(echo "$needed_repos") <(echo "$existing_repos") \
        | xargs -r -d '\n' printf '--enable="%s"\n'
    )"
    # We need eval here to turn quote chard in the sring into shell quotes
    eval sm_params="($disable_repo_params $enable_repo_params)"
    if [[ ${#sm_params[@]} -gt 0 ]]; then
        subscription-manager-log repos "${sm_params[@]}"
    else
        echo 'Already configured!'
    fi
}

subscription_exists() {
    local needed_subscription="${1:?}"
    subscription-manager list --consumed \
        | grep -qE "Subscription Name:\s+$needed_subscription"
}

get_subscription_pool_id() {
    local needed_subscription="${1:?}"
    subscription-manager list \
        --available --matches="$needed_subscription" --pool-only \
        | is_not_empty
}

subscription-manager-log() {
    echo "  - subscription-manager$(printf ' "%s"' "$@")"
    /usr/bin/subscription-manager "$@"
}

is_not_empty() {
    grep '.*'
}

die() {
    local err_code=1
    case "$1" in
        -[0-9]*) err_code=${1#-} ; shift ;;
        --) shift ;;
    esac
    echo "$@" 1>&2
    exit $err_code
}

main "$@"
