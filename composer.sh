#!/bin/bash
#
# Run composer in a container
#
# This script will attempt to mirror the host paths by using volumes for the
# following paths:
#   * $(pwd)
#   * $(dirname $COMPOSE_FILE) if it's set
#

set -e

SCRIPT_DIR="${BASH_SOURCE%/*}"

VERSION="${VERSION:-1-alpine}"
IMAGE="${IMAGE:-torvitas/composer:$VERSION}"

# You can set an environment file to be used using the $ENVIRONMENT_FILE
# environment variable.
ENVIRONMENT_FILE="${ENVIRONMENT_FILE:-$PWD/.env}"
if [ -e "$ENVIRONMENT_FILE" ]; then
  source "$ENVIRONMENT_FILE"
fi

# You can add additional volumes (or any docker run options) using
# the $COMPOSER_OPTIONS environment variable.
DOCKER_OPTIONS+=("${COMPOSER_OPTIONS[@]}")

# You can set the composer cache directory using the $COMPOSER_CACHE
# environment variable.
COMPOSER_CACHE="${COMPOSER_CACHE:-$PWD/tmp/composer}"
if [ -n "${COMPOSER_CACHE}" ]; then
  mkdir -p "${COMPOSER_CACHE}"
  DOCKER_OPTIONS+=(-v "$(readlink -f "${COMPOSER_CACHE}"):/composer/cache")
fi

# Mount directory of deployer configuration
if [ -n "${COMPOSER_FILE}" ]; then
  composer_dir=$(dirname "${COMPOSER_FILE}")
fi
if [ -n "${composer_dir}" ] && [ -d "${composer_dir}" ]; then
  DOCKER_OPTIONS+=(-v "$(readlink -f "${composer_dir}"):${composer_dir}")
fi

# shellcheck source=./dockerrun.sh
. "${SCRIPT_DIR}/dockerrun.sh" "${IMAGE}" "$@"
