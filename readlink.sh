#!/bin/sh -e

case "$1" in
  "-f")
    TARGET=$2

    cd "$(dirname "$TARGET")"
    TARGET=$(basename "$TARGET")

    # Iterate down a (possible) chain of symlinks
    while [ -L "$TARGET" ]
    do
      TARGET=$(readlink "$TARGET")
      cd "$(dirname "$TARGET")"
      TARGET=$(basename "$TARGET")
    done

    # Compute the canonicalized name by finding the physical path
    # for the directory we're in and appending the target file.
    DIR=`pwd -P`
    RESULT="${DIR%/}/${TARGET%/}"

    echo "$RESULT"
  ;;
  *)
    exec readlink "$@"
esac
