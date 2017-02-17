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

VERSION="${VERSION:-alpine-2.11.1-r0}"
IMAGE="${IMAGE:-torvitas/git:$VERSION}"

# You can set an environment file to be used using the $ENVIRONMENT_FILE
# environment variable.
ENVIRONMENT_FILE="${ENVIRONMENT_FILE:-$PWD/.env}"
if [ -e "$ENVIRONMENT_FILE" ]; then
    source "$ENVIRONMENT_FILE"
fi

# You can add additional volumes (or any docker run options) using
# the $COMPOSER_OPTIONS environment variable.
COMPOSER_OPTIONS="${COMPOSER_OPTIONS:-}"

# if we can't find an agent, start one, and restart the script.
if [ -z "$SSH_AUTH_SOCK" ] ; then
    eval "$(ssh-agent)"
fi

VOLUMES=()
# Setup volume mounts for composer config, context and ssh keys
if [ "$(pwd)" != '/' ]; then
    VOLUMES+=(-v "$(pwd):$(pwd)")
fi
VOLUMES+=(-v "$(readlink -f $SSH_AUTH_SOCK):/ssh-agent")
if [ -e "/etc/shadow" ]; then
    VOLUMES+=(-v "/etc/passwd:/etc/passwd:ro")
fi
if [ -e "/etc/passwd" ]; then
    VOLUMES+=(-v "/etc/shadow:/etc/shadow:ro")
fi
if [ -e "/etc/group" ]; then
    VOLUMES+=(-v "/etc/group:/etc/group:ro")
fi

SSH_KNOWN_HOSTS="${SSH_KNOWN_HOSTS:-$(pwd)/data/etc/ssh/known_hosts}"
if [ -e "$SSH_KNOWN_HOSTS" ]; then
    VOLUMES+=(-v "$SSH_KNOWN_HOSTS:$HOME/.ssh/known_hosts")
fi
# Only allocate tty if we detect one
if [ -t 1 ]; then
    DOCKER_RUN_OPTIONS+=(-t)
fi
if [ -t 0 ]; then
    DOCKER_RUN_OPTIONS+=(-i)
fi
exec docker run --rm \
    -u "$(id -u):$(id -g)" \
    -e SSH_AUTH_SOCK=/ssh-agent \
    -w "$(pwd)" \
    "${DOCKER_RUN_OPTIONS[@]}" $COMPOSER_OPTIONS "${VOLUMES[@]}" $IMAGE "$@"
