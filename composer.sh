#!/bin/bash -e
#
# Runs composer in a container.
#
# Additional to all inputs that dockerrun.sh accepts, following environment
# variables are available:
#
# - COMPOSER_CACHE: Defaults to $PWD/tmp/composer, directory where Composer will
#   save cached files to.
# - COMPOSER_FILE: Path to composer configuration, its directory will be mounted
#   into the container. If left empty, no additional mount will occur.
# - ENVIRONMENT_FILE: Path to a shell script to source for environment values.
#   Note that variables sourced from this file won't be passed into the Docker
#   container automatically, use DOCKER_OPTIONS for this.
#

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
