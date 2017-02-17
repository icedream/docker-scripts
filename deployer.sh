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

VERSION="4.0.0-php5-alpine"
IMAGE="torvitas/deployer:$VERSION"

# You can set an environment file to be used using the $ENVIRONMENT_FILE
# environment variable.
ENVIRONMENT_FILE=${ENVIRONMENT_FILE:-$PWD/.env}

if [ -n "$ENVIRONMENT_FILE" ]; then
    source $ENVIRONMENT_FILE
fi

# You can add additional volumes (or any docker run options) using
# the $DEPLOYER_OPTIONS environment variable.
DEPLOYER_OPTIONS=${DEPLOYER_OPTIONS:-}

# if we can't find an agent, start one, and restart the script.
if [ -z "$SSH_AUTH_SOCK" ] ; then
    eval $(ssh-agent -s)
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

# Setup volume mounts for deployer config, context and ssh keys
if [ "$(pwd)" != '/' ]; then
    VOLUMES+=(-v "$(pwd):$(pwd)")
    VOLUMES+=(-v "$(pwd):/src")
fi
if [ -n "$DEPLOYER_FILE" ]; then
    deployer_dir=$(dirname $DEPLOYER_FILE)
fi
if [ -n "$deployer_dir" ]; then
    VOLUMES+=(-v "$(readlink -f $deployer_dir):$deployer_dir")
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
    "${DOCKER_RUN_OPTIONS[@]}" $DEPLOYER_OPTIONS "${VOLUMES[@]}" -w "$(pwd)" $IMAGE "$@"
