#!/bin/bash -e
#
# Runs deployer in a container.
#
# Accepts all environment variables that dockerrun.sh accepts as well.
# Additionally, the following environment variables are accepted:
#
# - DEPLOYER_FILE: Path to deployer configuration, its directory will be mounted
#   into the container. If left empty, no additional mount will occur.
# - ENVIRONMENT_FILE: Path to a shell script to source for environment values.
#   Note that variables sourced from this file won't be passed into the Docker
#   container automatically, use DOCKER_OPTIONS for this.
#
# Also mounts current directory in /src.
#

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
