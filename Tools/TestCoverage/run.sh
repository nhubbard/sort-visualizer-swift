#!/bin/zsh
# Produce one source snapshot and result bundles for the requested coverage lanes.
set -euo pipefail

usage() {
  print -u2 'Usage: Tools/TestCoverage/run.sh --output DIR [--modules] [--ipad ID] [--catalyst-ui --development-team ID] [--intents ID --signing-identity SHA1]'
  exit 2
}

repository_root=${0:A:h:h:h}
output=''
run_modules=false
ipad_id=''
run_catalyst_ui=false
intents_id=''
signing_identity=''
development_team=''

while (( $# )); do
  case "$1" in
    --output) (( $# >= 2 )) || usage; output=$2; shift 2 ;;
    --modules) run_modules=true; shift ;;
    --ipad) (( $# >= 2 )) || usage; ipad_id=$2; shift 2 ;;
    --catalyst-ui) run_catalyst_ui=true; shift ;;
    --intents) (( $# >= 2 )) || usage; intents_id=$2; shift 2 ;;
    --signing-identity) (( $# >= 2 )) || usage; signing_identity=$2; shift 2 ;;
    --development-team) (( $# >= 2 )) || usage; development_team=$2; shift 2 ;;
    *) usage ;;
  esac
done
[[ -n "$output" ]] || usage
[[ "$run_modules" == true || -n "$ipad_id" || "$run_catalyst_ui" == true || -n "$intents_id" ]] || usage
[[ -z "$intents_id" || -n "$signing_identity" ]] || usage

mkdir -p "$output"
output=${output:A}
cd "$repository_root"
tuist generate

python3 Tools/TestCoverage/report.py snapshot --output "$output/sources.json"
python3 - "$output/run.json" "$run_modules" "$ipad_id" "$run_catalyst_ui" "$intents_id" <<'PY'
import json
import sys
from pathlib import Path

path, modules, ipad, catalyst, intents = sys.argv[1:]
Path(path).write_text(json.dumps({
    "modules": modules == "true",
    "ipadSimulatorID": ipad or None,
    "catalystUI": catalyst == "true",
    "appIntentsSimulatorID": intents or None,
}, indent=2) + "\n")
PY
results=()
behavioral=()
failures=()

if [[ "$run_modules" == true ]]; then
  for test_dir in Modules/*/Tests(N/); do
    test_sources=("$test_dir"/**/*.swift(N))
    (( ${#test_sources} )) || continue
    module=${test_dir:h:t}
    result="$output/module-$module.xcresult"
    print "Running module $module"
    if xcodebuild test -quiet -workspace 'Sort Symphony.xcworkspace' -scheme "$module" \
      -destination 'platform=macOS,variant=Mac Catalyst' -enableCodeCoverage YES \
      -resultBundlePath "$result"; then
      results+=(--result "catalyst/$module=$result")
    else
      failures+=("catalyst/$module")
    fi
  done
  result="$output/auv3-extension-component.xcresult"
  print 'Running AUv3 extension component tests'
  if xcodebuild test -quiet -workspace 'Sort Symphony.xcworkspace' \
    -scheme 'AUv3ExtensionComponentTests' \
    -destination 'platform=macOS,variant=Mac Catalyst' -enableCodeCoverage YES \
    -resultBundlePath "$result"; then
    results+=(--result "catalyst/AUv3ExtensionComponentTests=$result")
  else
    failures+=("catalyst/AUv3ExtensionComponentTests")
  fi
fi

if [[ -n "$ipad_id" ]]; then
  result="$output/ipad-ui.xcresult"
  print 'Running iPad UI suite'
  if xcodebuild test -quiet -workspace 'Sort Symphony.xcworkspace' -scheme 'Sort SymphonyUITests' \
    -destination "platform=iOS Simulator,id=$ipad_id" -enableCodeCoverage YES \
    -resultBundlePath "$result"; then
    results+=(--result "ios/ipad-ui=$result")
  else
    failures+=("ios/ipad-ui")
  fi
fi

if [[ "$run_catalyst_ui" == true ]]; then
  result="$output/catalyst-ui.xcresult"
  print 'Running Mac Catalyst UI suite'
  catalyst_signing=()
  [[ -z "$development_team" ]] || catalyst_signing+=("DEVELOPMENT_TEAM=$development_team")
  if xcodebuild test -quiet -workspace 'Sort Symphony.xcworkspace' -scheme 'Sort SymphonyUITests' \
    -destination 'platform=macOS,variant=Mac Catalyst' -enableCodeCoverage YES \
    -resultBundlePath "$result" CODE_SIGNING_ALLOWED=YES \
    CODE_SIGN_IDENTITY='Apple Development' "${catalyst_signing[@]}"; then
    if xcrun xccov view --archive --file-list --json "$result" >/dev/null 2>&1; then
      results+=(--result "catalyst/ui=$result")
    else
      print -u2 'Catalyst UI tests passed, but Xcode did not provide a readable coverage archive; recording a behavioral-only result.'
      behavioral+=(--behavioral-result "catalyst/ui=$result")
    fi
  else
    failures+=("catalyst/ui")
  fi
fi

if [[ -n "$intents_id" ]]; then
  result="$output/app-intents.xcresult"
  print 'Running App Intents system suite'
  if Tools/AppIntentsTesting/run.sh "$intents_id" "$signing_identity" "$result"; then
    results+=(--result "ios/app-intents=$result")
  else
    failures+=("ios/app-intents")
  fi
fi

printf '%s\n' "${failures[@]}" > "$output/failed-lanes.txt"
if (( ${#results} + ${#behavioral} )); then
  python3 Tools/TestCoverage/report.py report --manifest "$output/sources.json" \
    "${results[@]}" "${behavioral[@]}" --changed-base HEAD --verify-tests \
    --output "$output/coverage.json" --markdown "$output/coverage.md"
fi
if (( ${#failures} )); then
  print -u2 "Coverage run is incomplete. Failed lanes are recorded in $output/failed-lanes.txt"
  exit 1
fi
