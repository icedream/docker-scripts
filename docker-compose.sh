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


# Setup options for connecting to docker host
if [ -z "$DOCKER_HOST" ]; then
    DOCKER_HOST="/var/run/docker.sock"
fi
if [ -S "$DOCKER_HOST" ]; then
    DOCKER_ADDR="-v $DOCKER_HOST:$DOCKER_HOST -e DOCKER_HOST"
else
    DOCKER_ADDR="-e DOCKER_HOST -e DOCKER_TLS_VERIFY -e DOCKER_CERT_PATH"
fi

VOLUMES=()
# Setup volume mounts for compose config and context
if [ "$(pwd)" != '/' ]; then
    VOLUMES+=(-v "$(pwd):$(pwd)")
fi
if [ -n "$COMPOSE_FILE" ]; then
    compose_dir=$(dirname $COMPOSE_FILE)
fi
if [ -n "$compose_dir" ]; then
    VOLUMES+=(-v "$compose_dir:$compose_dir")
fi
if [ -n "$HOME" ]; then
    VOLUMES+=(-v "$HOME:$HOME")
fi

# Only allocate tty if we detect one
DOCKER_RUN_OPTIONS=()
if [ -t 1 ]; then
    DOCKER_RUN_OPTIONS+=(-t)
fi
if [ -t 0 ]; then
    DOCKER_RUN_OPTIONS+=(-i)
fi

exec docker run --rm \
    -u "$(id -u):$(id -g)" \
    -w "$(pwd)" \
    "${DOCKER_RUN_OPTIONS[@]}" $DOCKER_ADDR $COMPOSE_OPTIONS "${VOLUMES[@]}" $IMAGE "$@"
