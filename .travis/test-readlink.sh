#!/bin/sh -e

must_f() {
  src="$1"
  target="$2"

  printf "Checking $src -> $target..."
  if [ "$(readlink.sh -f "$src")" = "$target" ]; then
    echo " ok"
  else
    echo " failed"
    exec false
  fi
}

mkdir -p testing-dir
touch testing-file
ln -sf testing-dir testing-dir-link
ln -sf testing-file testing-file-link

must_f "testing-dir" "${PWD}/testing-dir"
must_f "testing-dir-link" "${PWD}/testing-dir"
must_f "testing-file" "${PWD}/testing-file"
must_f "testing-file-link" "${PWD}/testing-file"

echo All seems good with readlink.sh.
