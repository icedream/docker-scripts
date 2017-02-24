#!/bin/bash
#
# Run docker-compose in a container
#
# This script will attempt to mirror the host paths by using volumes for the
# following paths:
#   * $(pwd)
#   * $(dirname $COMPOSE_FILE) if it's set
#   * $HOME if it's set
#
# You can add additional volumes (or any docker run options) using
# the $COMPOSE_OPTIONS environment variable.
#

set -e

SCRIPT_DIR="${BASH_SOURCE%/*}"

VERSION="${VERSION:-1.11.1}"
IMAGE="${IMAGE:-docker/compose:$VERSION}"

DOCKER_OPTIONS=();

# Setup options for connecting to docker host
if [ -z "$DOCKER_HOST" ]; then
  DOCKER_HOST="/var/run/docker.sock"
fi
if [ -S "$DOCKER_HOST" ]; then
  # Local Docker host
  DOCKER_OPTIONS+=(
    -v "${DOCKER_HOST}:${DOCKER_HOST}"
    -e DOCKER_HOST
    -e DOCKER_TLS_VERIFY
    -e DOCKER_CERT_PATH
  )
else
  # Remote Docker host
  DOCKER_OPTIONS+=(
    -e "DOCKER_HOST=${DOCKER_HOST}"
    -e "DOCKER_TLS_VERIFY=${DOCKER_TLS_VERIFY}"
    -e "DOCKER_CERT_PATH=${DOCKER_CERT_PATH}"
  )
fi

# Mount directory of compose project file if any given.
if [ -n "${COMPOSE_FILE}" ] && [ -f "${COMPOSE_FILE}" ]; then
  compose_dir=$(dirname "${COMPOSE_FILE}")
  DOCKER_OPTIONS+=(-v "${compose_dir}:${compose_dir}")
fi

unset DOCKER_HOST
unset DOCKER_TLS_VERIFY
unset DOCKER_CERT_PATH

# shellcheck source=./dockerrun.sh
. "${SCRIPT_DIR}/dockerrun.sh" "${IMAGE}" "$@"
