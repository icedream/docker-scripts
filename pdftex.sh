#!/bin/bash -e

SCRIPT_DIR="${BASH_SOURCE%/*}"

IMAGE=jojomi/latex

# shellcheck source=./_common.sh
. "${SCRIPT_DIR}/dockerrun.sh" "${IMAGE}" pdftex "$@"
