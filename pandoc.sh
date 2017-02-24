#!/bin/bash -e

SCRIPT_DIR="${BASH_SOURCE%/*}"

IMAGE=conoria/alpine-pandoc

# shellcheck source=./_common.sh
. "${SCRIPT_DIR}/dockerrun.sh" "${IMAGE}" pandoc "$@"
