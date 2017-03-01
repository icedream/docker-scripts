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
DOCKER_OPTIONS+=(
  -u "${UID}:$(id -g)"
  -v "$(mirror_volume "${HOME}")"
  -v "$(mirror_volume /etc/group ro)"
  -v "$(mirror_volume /etc/gshadow ro)"
  -v "$(mirror_volume /etc/passwd ro)"
  -v "$(mirror_volume /etc/shadow ro)"
)

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
fi
DOCKER_OPTIONS+=(
  -e "SSH_AUTH_SOCK=/ssh-agent"
  -v "${SSH_AUTH_SOCK}:/ssh-agent"
)

# Only allocate tty if we detect one
if [ -t 1 ]; then
  DOCKER_OPTIONS+=(-t)
fi
if [ -t 0 ]; then
  DOCKER_OPTIONS+=(-i)
fi

# Append supplementary groups to DOCKER_OPTIONS
for val in $(id -G); do
  DOCKER_OPTIONS+=(--group-add "${val}")
done

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

exec docker run --rm \
  "${DOCKER_OPTIONS[@]}" \
  "${IMAGE}" \
  "$@"
