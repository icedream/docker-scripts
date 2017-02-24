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

# Pass through environment variables that docker-compose supports, see
# https://docs.docker.com/compose/reference/envvars/ for the full list.
DOCKER_OPTIONS+=(
  -e COMPOSE_PROJECT_NAME
  -e COMPOSE_FILE
  -e COMPOSE_API_VERSION
  -e COMPOSE_HTTP_TIMEOUT
  -e COMPOSE_TLS_VERSION
  -e COMPOSE_CONVERT_WINDOWS_PATHS
)

# Setup options for connecting to docker host
# DOCKER_HOST is not just a path to the socket, but may be prefixed with "unix://".
DOCKER_HOST="${DOCKER_HOST:-unix:///var/run/docker.sock}"
docker_host_file="${DOCKER_HOST#unix://}"
if [ -S "${docker_host_file}" ]; then
  # Local Docker host
  DOCKER_OPTIONS+=(
    -v "${docker_host_file}:${docker_host_file}"
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
  unset DOCKER_HOST
  unset DOCKER_TLS_VERIFY
  unset DOCKER_CERT_PATH
fi

# Mount certificate path if any given.
if [ -n "${DOCKER_CERT_PATH}" ] && [ -d "${DOCKER_CERT_PATH}" ]; then
  DOCKER_OPTIONS+=(-v "${DOCKER_CERT_PATH}:${DOCKER_CERT_PATH}")
fi

# Mount directory of compose project file if any given.
if [ -n "${COMPOSE_FILE}" ] && [ -f "${COMPOSE_FILE}" ]; then
  compose_dir=$(dirname "${COMPOSE_FILE}")
  DOCKER_OPTIONS+=(-v "${compose_dir}:${compose_dir}")
fi

# shellcheck source=./dockerrun.sh
. "${SCRIPT_DIR}/dockerrun.sh" "${IMAGE}" "$@"
