#!/bin/sh -e
if hash greadlink >/dev/null 2>&1; then
  set -x
  exec greadlink "$@"
else
  set -x
  exec readlink "$@"
fi
