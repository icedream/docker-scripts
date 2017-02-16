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

VERSION="1-alpine"
IMAGE="torvitas/composer:$VERSION"

# You can set an environment file to be used using the $ENVIRONMENT_FILE
# environment variable.
ENVIRONMENT_FILE=${ENVIRONMENT_FILE:-$PWD/.env}

if [ -n "$ENVIRONMENT_FILE" ]; then
    source $ENVIRONMENT_FILE
fi

# You can add additional volumes (or any docker run options) using
# the $COMPOSER_OPTIONS environment variable.
COMPOSER_OPTIONS=${COMPOSER_OPTIONS:-}

# You can set a folder to be mapped to /root/.ssh using the
# $SSH_DIR environment variable.
SSH_DIR=${SSH_DIR:-}

# if we can't find an agent, start one, and restart the script.
if [ -z "$SSH_AUTH_SOCK" ] ; then
    eval $(ssh-agent)
fi
# Setup volume mounts for composer config, context and ssh keys
if [ "$(pwd)" != '/' ]; then
    VOLUMES="-v $(pwd):$(pwd)"
fi

# You can set the composer cache directory using the $COMPOSER_CACHE
# environment variable.
COMPOSER_CACHE=${COMPOSER_CACHE:-$PWD/tmp/composer}
if [[ -n "$COMPOSER_CACHE" ]]; then
    mkdir -p "$COMPOSER_CACHE";
    VOLUMES="$VOLUMES -v $(cd $COMPOSER_CACHE; pwd):/composer/cache"
fi

if [ -n "$COMPOSER_FILE" ]; then
    composer_dir=$(dirname $COMPOSER_FILE)
fi
if [[ -n "$composer_dir" && -d "$composer_dir" ]]; then
    VOLUMES="$VOLUMES -v $(cd $composer_dir; pwd):$composer_dir"
fi
if [ -n "$SSH_DIR" ]; then
    mkdir -p "$SSH_DIR";
    VOLUMES="$VOLUMES -v $(cd $SSH_DIR; pwd):/root/.ssh"
fi
if [ -e "./data/etc/ssh/known_hosts" ]; then
    VOLUMES="$VOLUMES -v $(pwd)/data/etc/ssh/known_hosts:$HOME/.ssh/known_hosts"
fi
if [ -e "/etc/shadow" ]; then
    VOLUMES="$VOLUMES -v /etc/shadow:/etc/shadow"
fi
if [ -e "/etc/passwd" ]; then
    VOLUMES="$VOLUMES -v /etc/passwd:/etc/passwd"
fi
# Only allocate tty if we detect one
if [ -t 1 ]; then
    DOCKER_RUN_OPTIONS="-t"
fi
if [ -t 0 ]; then
    DOCKER_RUN_OPTIONS="$DOCKER_RUN_OPTIONS -i"
fi
exec docker run --rm \
    -u $(id -u) \
    -e SSH_AUTH_SOCK=/ssh-agent \
    -v $(readlink -f $SSH_AUTH_SOCK):/ssh-agent \
    $DOCKER_RUN_OPTIONS $COMPOSER_OPTIONS $VOLUMES -w "$(pwd)" $IMAGE "$@"
