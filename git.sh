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

VERSION="${VERSION:-alpine-2.11.1-r0}"
IMAGE="${IMAGE:-torvitas/git:$VERSION}"

# You can set an environment file to be used using the $ENVIRONMENT_FILE
# environment variable.
ENVIRONMENT_FILE="${ENVIRONMENT_FILE:-$PWD/.env}"
if [ -e "$ENVIRONMENT_FILE" ]; then
  source "$ENVIRONMENT_FILE"
fi

DOCKER_OPTIONS+=(
  -e GIT_ALTERNATE_OBJECT_DIRECTORIES
  -e GIT_AUTHOR_DATE
  -e GIT_AUTHOR_EMAIL
  -e GIT_AUTHOR_NAME
  -e GIT_COMMITTER_DATE
  -e GIT_COMMITTER_EMAIL
  -e GIT_COMMITTER_NAME
  -e GIT_CONFIG_NOSYSTEM
  -e GIT_DIFF_OPTS
  -e GIT_DIR
  -e GIT_GLOB_PATHSPECS
  -e GIT_HTTP_USER_AGENT
  -e GIT_ICASE_PATHSPECS
  -e GIT_INDEX_FILE
  -e GIT_LITERAL_PATHSPECS
  -e GIT_MERGE_VERBOSITY
  -e GIT_NOGLOB_PATHSPECS
  -e GIT_OBJECT_DIRECTORY
  -e GIT_SSL_NO_VERIFY
  -e GIT_WORK_TREE
)

# shellcheck source=./dockerrun.sh
. "${SCRIPT_DIR}/dockerrun.sh" "${IMAGE}" "$@"
