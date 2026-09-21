#!/bin/zsh
set -euo pipefail

prototype_dir="${0:A:h}"
build_dir="${INSTRUMENTS_BUILD_DIR:-/private/tmp/instruments-prototype-build}"
if [[ ! -f "$build_dir/libInstrumentsPrototype.dylib" ]]; then
  "$prototype_dir/build.sh"
fi
developer_dir="$(xcode-select -p)"
export DYLD_INSERT_LIBRARIES="$build_dir/libInstrumentsPrototype.dylib"
export INSTRUMENTS_INJECT_RUN=1
export INSTRUMENTS_LISTEN_PORT="${INSTRUMENTS_LISTEN_PORT:-27727}"
exec "$developer_dir/usr/bin/xctrace"
