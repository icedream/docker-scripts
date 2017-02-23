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

VERSION="${VERSION:-1.11.1}"
IMAGE="${IMAGE:-docker/compose:$VERSION}"

DOCKER_OPTIONS=();

# Setup options for connecting to docker host
if [ -z "$DOCKER_HOST" ]; then
    DOCKER_HOST="/var/run/docker.sock"
fi
if [ -S "$DOCKER_HOST" ]; then
    DOCKER_OPTIONS+=(-v "${DOCKER_HOST}:${DOCKER_HOST}")
    DOCKER_OPTIONS+=(-e "DOCKER_HOST")
else
    DOCKER_OPTIONS+=(-e "DOCKER_HOST")
    DOCKER_OPTIONS+=(-e "DOCKER_TLS_VERIFY")
    DOCKER_OPTIONS+=(-e "DOCKER_CERT_PATH")
fi

# Setup volume mounts for compose config and context
if [ "${PWD}" != '/' ]; then
    DOCKER_OPTIONS+=(-v "${PWD}:${PWD}")
fi
if [ -n "$COMPOSE_FILE" ]; then
    compose_dir=$(dirname ${COMPOSE_FILE})
fi
if [ -n "$compose_dir" ]; then
    DOCKER_OPTIONS+=(-v "$compose_dir:$compose_dir")
fi
if [ -n "$HOME" ]; then
    DOCKER_OPTIONS+=(-v "${HOME}:${HOME}")
fi

# Only allocate tty if we detect one
if [ -t 1 ]; then
    DOCKER_OPTIONS+=(-t)
fi
if [ -t 0 ]; then
    DOCKER_OPTIONS+=(-i)
fi

GROUPS=(id -G)
printf -v GROUP_ADD -- "--group-add %s " "${GROUPS[@]}"

unset DOCKER_HOST
unset DOCKER_TLS_VERIFY
unset DOCKER_CERT_PATH

exec docker run --rm \
    -u "$(id -u):$(ls -Cn /var/run/docker.sock | awk '{print $4}')" \
    ${GROUP_ADD} \
    -w "${PWD}" \
    "${DOCKER_OPTIONS[@]}" ${COMPOSE_OPTIONS} ${IMAGE} "$@"
