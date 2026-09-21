#!/bin/zsh
set -euo pipefail

prototype_dir="${0:A:h}"
archive="${1:-/private/tmp/InstrumentsPrototype-Xcode27.tar.gz}"
mkdir -p "${archive:h}"
tar -czf "$archive" \
  --exclude='InstrumentsPrototype/__pycache__' \
  --exclude='InstrumentsPrototype/*.trace' \
  --exclude='InstrumentsPrototype/*.lock' \
  -C "${prototype_dir:h}" InstrumentsPrototype
print -r -- "Packaged $archive"
