#!/bin/bash -e
#
# This script mounts all relevant paths from the host system straight into the
# container to allow for transparent usage of Docker images.
#
# Environment variables that this script will accept:
#
# - DOCKER_PULL_OPTIONS: Flags that will be passed along with `docker pull`.
# - DOCKER_OPTIONS: Flags that will be passed along with `docker run`.
# - NO_PULL: Do not attempt to pull the wanted Docker image before running it.
#   By default this script will update to the latest version of the Docker image
#   that matches, this environment variable will prevent it from happening if
#   set to anything non-zero.
#

SCRIPT_DIR="${BASH_SOURCE%/*}"

# Possible values for $OS:
# - Linux (Debian, Ubuntu, Fedora, Arch Linux, Alpine, ...)
# - Darwin (macOS/Mac OS X)
OS="$(uname)"

# Generates a volume definition that maps the volume into the container at the
# exact same path as the host.
mirror_volume() {
  echo -n "$("${SCRIPT_DIR}/readlink.sh" -f "$1"):$1"
  if [ ! -z "$2" ]; then
    echo -n ":$2"
  fi
}

# Read image to use from arguments.
IMAGE="$1"
shift 1

# Mirror user and group
# (only supported for Linux, others don't use /etc/passwd-ish routines)
if [ "$OS" = "Linux" ]; then
  DOCKER_OPTIONS+=(
    -u "${UID}:$(id -g)"
    -v "$(mirror_volume "${HOME}")"
  )
  if [ -f "/etc/group" ]; then
    DOCKER_OPTIONS+=(-v "$(mirror_volume /etc/group ro)")
  fi
  if [ -f "/etc/gshadow" ]; then
    DOCKER_OPTIONS+=(-v "$(mirror_volume /etc/gshadow ro)")
  fi
  if [ -f "/etc/passwd" ]; then
    DOCKER_OPTIONS+=(-v "$(mirror_volume /etc/passwd ro)")
  fi
  if [ -f "/etc/shadow" ]; then
    DOCKER_OPTIONS+=(-v "$(mirror_volume /etc/shadow ro)")
  fi

  # Append supplementary groups to DOCKER_OPTIONS
  for val in $(id -G); do
    DOCKER_OPTIONS+=(--group-add "${val}")
  done
fi

# Pass through current working directory.
# @TODO - Find a more consistent solution if possible.
if [ "${PWD}" = "/" ]; then
  DOCKER_OPTIONS+=(
    -v "$("${SCRIPT_DIR}/readlink.sh" -f "${PWD}"):/host/${PWD}"
    -w "/host/${PWD}"
  )
else
  DOCKER_OPTIONS+=(
    -v "$(mirror_volume "${PWD}")"
    -w "${PWD}"
  )
fi

# Mount SSH known hosts.
# @TODO - Merge in ssh_known_hosts from user & system dirs using temp file?
if [ -n "${SSH_KNOWN_HOSTS}" ]; then
  DOCKER_OPTIONS+=(-v "${SSH_KNOWN_HOSTS}:/etc/ssh/ssh_known_hosts")
fi

# Pass through SSH agent, if we can't find an agent, start one.
if [ -z "${SSH_AUTH_SOCK}" ] || [ ! -e "${SSH_AUTH_SOCK}" ]; then
  eval "$(ssh-agent -s)"
  trap 'eval "$(ssh-agent -k)"' EXIT
fi
DOCKER_OPTIONS+=(
  -e SSH_AUTH_SOCK
  -v "$("${SCRIPT_DIR}/readlink.sh" -f "${SSH_AUTH_SOCK}"):${SSH_AUTH_SOCK}"
)

# Only allocate tty if we detect one
if [ -t 1 ]; then
  DOCKER_OPTIONS+=(-t)
fi
if [ -t 0 ]; then
  DOCKER_OPTIONS+=(-i)
fi

if [ -z "${NO_PULL}" ]; then
  docker pull \
    "${DOCKER_PULL_OPTIONS[@]}" \
    "${IMAGE}"
fi

if [ -n "${SCRIPT_DEBUG}" ]; then
  echo docker run --rm \
    "${DOCKER_OPTIONS[@]}" \
    "${IMAGE}" \
    "$@"
fi

# Do not use "exec" to allow exit traps to run
docker run --rm \
  "${DOCKER_OPTIONS[@]}" \
  "${IMAGE}" \
  "$@"
exit "$?"
