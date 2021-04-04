#!/usr/bin/env bash

vagrant_wrapper() {
    DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" # path where this file lives

    local user_command=$@

    # we assume that we are outside the VM if command `vagrant` is available
    if [[ -x "$(command -v vagrant)" ]]; then
        (cd ".manala" && vagrant ssh -- "cd /srv/app && ${user_command}")
    else
        (cd "${DIR}" && eval ${user_command})
    fi
}

vagrant_wrapper $@
