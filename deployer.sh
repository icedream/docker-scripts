#!/bin/bash
#
# Run deployer in a container
#
# This script will attempt to mirror the host paths by using volumes for the
# following paths:
#   * $(pwd)
#   * $(dirname $COMPOSE_FILE) if it's set
#   * $HOME if it's set
#

set -e

SCRIPT_DIR="${BASH_SOURCE%/*}"

VERSION="${VERSION:-4.0.0-php5-alpine}"
IMAGE="${IMAGE:-torvitas/deployer:$VERSION}"

# You can set an environment file to be used using the $ENVIRONMENT_FILE
# environment variable.
ENVIRONMENT_FILE=${ENVIRONMENT_FILE:-$PWD/.env}
if [ -e "$ENVIRONMENT_FILE" ]; then
  source $ENVIRONMENT_FILE
fi

# You can add additional volumes (or any docker run options) using
# the $DEPLOYER_OPTIONS environment variable.
DOCKER_OPTIONS+=("${DEPLOYER_OPTIONS[@]}")

# Additional mounts
DOCKER_OPTIONS+=(-v "${PWD}:/src")

# Mount directory of deployer configuration
if [ -n "${DEPLOYER_FILE}" ]; then
  deployer_dir=$(dirname "${DEPLOYER_FILE}")
fi
if [ -n "${deployer_dir}" ]; then
  DOCKER_OPTIONS+=(-v "${deployer_dir}:${deployer_dir}")
fi

# shellcheck source=./dockerrun.sh
. "${SCRIPT_DIR}/dockerrun.sh" "${IMAGE}" "$@"
