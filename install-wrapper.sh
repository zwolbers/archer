#! /usr/bin/env bash

set -ex

# Expected arguments:
readonly install_script="$1"
readonly settings_script="$2"
readonly chroot_script="$3"

#
# Skip argument parsing/validation/help messages/etc. because
#   1) Bash is awful
#   2) This script shouldn't be called manually anyway
#
# Any issues will still be detected; the error message may just be lacking.
#

function step() {
    echo -e "\e[1;32m$1\e[m"        # Green
}
function msg() {
    echo -e "\e[1;35m$1\e[m"        # Magenta
}
function err() {
    echo -e "\e[1;31m$1\e[m" >&2    # Red
}

# Source and validate settings
. "${settings_script}"
if [[ -z "${hostname}" ]] \
    || [[ -z "${username}" ]] \
    || [[ -z "${pass_root}" ]] \
    || [[ -z "${pass_user}" ]]; then
    err "Error: Unset variables in ${settings_script}"
    exit 1
fi

. "${chroot_script}"
if [[ -z "${chroot}" ]] \
    || [[ -z "${chroot_user}": ]]; then
    err "Error: Unset variables in ${chroot_script}"
    exit 1
fi

# Execute the script
step "$(basename ${install_script})"
. "${install_script}"
msg "Done"

