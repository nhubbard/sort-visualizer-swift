#!/bin/zsh
set -euo pipefail

prototype_dir="${0:A:h}"
developer_dir="$(xcode-select -p)"
xcode_contents="${developer_dir%/Developer}"
frameworks_dir="$xcode_contents/Applications/Instruments.app/Contents/Frameworks"
shared_frameworks_dir="$xcode_contents/SharedFrameworks"
build_dir="${INSTRUMENTS_BUILD_DIR:-/private/tmp/instruments-prototype-build}"
mkdir -p "$build_dir"

clang -fobjc-arc -DINSTRUMENTS_INJECT_BUILD -c \
  "$prototype_dir/probe.m" -o "$build_dir/probe.o"
clang -c "$prototype_dir/injected_entry.c" -o "$build_dir/injected_entry.o"

swiftc -module-cache-path "$build_dir/swift-module-cache" \
  -Xcc "-fmodules-cache-path=$build_dir/clang-module-cache" \
  -emit-library -emit-module -module-name InstrumentsPrototype \
  "$prototype_dir/RecordingSession.swift" \
  "$prototype_dir/TraceSettings.swift" \
  "$prototype_dir/MacCompatibility.generated.swift" \
  "$prototype_dir/TraceTriggerServer.swift" \
  "$build_dir/probe.o" "$build_dir/injected_entry.o" \
  -o "$build_dir/libInstrumentsPrototype.dylib" \
  -F "$frameworks_dir" -F "$shared_frameworks_dir" \
  -framework CoreData -framework Security -framework InstrumentsPlugIn \
  -framework InstrumentsKit -framework InstrumentsTrace \
  -framework InstrumentsPackaging -framework DVTInstrumentsFoundation \
  -Xlinker -rpath -Xlinker "$frameworks_dir" \
  -Xlinker -rpath -Xlinker "$shared_frameworks_dir"

print -r -- "Built $build_dir/libInstrumentsPrototype.dylib"
print -r -- "Swift module: $build_dir/InstrumentsPrototype.swiftmodule"
