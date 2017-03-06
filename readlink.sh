#!/bin/sh -e
if hash greadlink >/dev/null 2>&1; then
  exec greadlink "$@"
else
  exec readlink "$@"
fi
