#!/bin/zsh
set -euo pipefail

if (( $# != 4 )); then
  print -u2 "Usage: $0 <xcodebuild-destination> <write|observe|observe-delete|observe-absent|delete> <marker-suffix> <result.xcresult>"
  exit 2
fi

destination=$1
phase=$2
suffix=$3
result_bundle=$4
if [[ ! $suffix =~ '^[A-Za-z0-9-]+$' ]]; then
  print -u2 "Marker suffix must contain only letters, numbers, and hyphens"
  exit 2
fi
case $phase in
  write) test_name=testWriteCanaryOnFirstDevice ;;
  observe) test_name=testObserveCanaryOnSecondDevice ;;
  observe-delete) test_name=testObserveServerDeletion ;;
  observe-absent) test_name=testDeletedCanaryIsAbsentAfterRelaunch ;;
  delete) test_name=testDeleteCanaryAfterBothDevicesObservedIt ;;
  *) print -u2 "Unknown phase: $phase"; exit 2 ;;
esac

repository_root=${0:A:h:h:h}
if [[ $destination == platform=macOS,* ]]; then
  derived_data=/private/tmp/sort-symphony-cloudkit-canary-mac-derived
else
  derived_data=/private/tmp/sort-symphony-cloudkit-canary-ios-derived
fi
products=$derived_data/Build/Products
cd "$repository_root"

xcodebuild build-for-testing -quiet \
  -workspace 'Sort Symphony.xcworkspace' \
  -scheme 'Sort SymphonyUITests' \
  -destination "$destination" \
  -derivedDataPath "$derived_data" \
  CODE_SIGN_IDENTITY='Apple Development' DEVELOPMENT_TEAM=676UP3S3AH

xctestrun=($products/*UITests_*.xctestrun(N))
if (( ${#xctestrun} != 1 )); then
  print -u2 "Expected one UI-test .xctestrun file in $products"
  exit 1
fi

configured_run=$products/CloudKitCanary.xctestrun
trap 'rm -f "$configured_run"' EXIT
python3 - "$xctestrun[1]" "$configured_run" "$suffix" <<'PY'
import os
import plistlib
import sys

with open(sys.argv[1], "rb") as source:
    configuration = plistlib.load(source)
targets = [
    item for item in configuration.values()
    if isinstance(item, dict) and item.get("ProductModuleName") == "SortSymphonyUITests"
]
if len(targets) != 1:
    raise SystemExit("Expected one SortSymphonyUITests test configuration")
environment = targets[0].setdefault("EnvironmentVariables", {})
environment["HIS02_RUN_CANARY"] = "1"
environment["HIS02_CANARY_SUFFIX"] = sys.argv[3]
if hold := os.environ.get("HIS02_EXPORT_HOLD_SECONDS"):
    environment["HIS02_EXPORT_HOLD_SECONDS"] = hold
with open(sys.argv[2], "wb") as destination:
    plistlib.dump(configuration, destination)
PY

mkdir -p "${result_bundle:h}"
xcodebuild test-without-building \
  -xctestrun "$configured_run" \
  -destination "$destination" \
  "-only-testing:Sort SymphonyUITests/CloudKitHistorySyncUITests/$test_name" \
  -resultBundlePath "$result_bundle"
