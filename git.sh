#!/bin/bash
#
# Runs git in a container.
#
# Accepts all environment variables that dockerrun.sh accepts as well. Passes
# through the following environment variables for git:
#
# - GIT_ALTERNATE_OBJECT_DIRECTORIES
# - GIT_AUTHOR_DATE
# - GIT_AUTHOR_EMAIL
# - GIT_AUTHOR_NAME
# - GIT_COMMITTER_DATE
# - GIT_COMMITTER_EMAIL
# - GIT_COMMITTER_NAME
# - GIT_CONFIG_NOSYSTEM
# - GIT_DIFF_OPTS
# - GIT_DIR
# - GIT_GLOB_PATHSPECS
# - GIT_HTTP_USER_AGENT
# - GIT_ICASE_PATHSPECS
# - GIT_INDEX_FILE
# - GIT_LITERAL_PATHSPECS
# - GIT_MERGE_VERBOSITY
# - GIT_NOGLOB_PATHSPECS
# - GIT_OBJECT_DIRECTORY
# - GIT_SSL_NO_VERIFY
# - GIT_WORK_TREE
#
# Accepts the following additional environment variables:
#
# - ENVIRONMENT_FILE: Path to a shell script to source for environment values.
#   Note that variables sourced from this file won't be passed into the Docker
#   container automatically, use DOCKER_OPTIONS for this.
#

# For a full list of environment variables that Git supports, check
# https://git-scm.com/book/tr/v2/Git-Internals-Environment-Variables.

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
