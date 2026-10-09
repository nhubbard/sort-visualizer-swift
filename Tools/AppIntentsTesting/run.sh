#!/bin/zsh
set -euo pipefail

if (( $# < 2 || $# > 4 )); then
  print -u2 "Usage: $0 <iOS-27-iPad-simulator-ID> <Apple-Development-signing-identity> [result.xcresult] [test-identifier]"
  exit 2
fi

simulator_id=$1
signing_identity=$2
repository_root=${0:A:h:h:h}
derived_data=/private/tmp/sort-symphony-app-intents-testing-derived
products=$derived_data/Build/Products
app=$products/Debug-iphonesimulator/SortSymphony.app
runner=$products/Debug-iphonesimulator/SortSymphonyAppIntentsUITests-Runner.app
test_bundle=$runner/PlugIns/SortSymphonyAppIntentsUITests.xctest

cd "$repository_root"
xcodebuild build-for-testing -quiet \
  -workspace 'Sort Symphony.xcworkspace' \
  -scheme 'Sort SymphonyAppIntentsUITests' \
  -destination "platform=iOS Simulator,id=$simulator_id" \
  -derivedDataPath "$derived_data" \
  -enableCodeCoverage YES \
  CODE_SIGN_IDENTITY='Apple Development'

# Xcode normally ad hoc signs simulator products. AppIntentsTesting's system service requires
# both the app and test runner to carry a matching development team signature.
codesign --force --deep --sign "$signing_identity" --timestamp=none "$app"
codesign --force --deep --sign "$signing_identity" --timestamp=none "$test_bundle"
codesign --force --deep --sign "$signing_identity" --timestamp=none "$runner"

xctestrun=($products/*.xctestrun(N))
if (( ${#xctestrun} != 1 )); then
  print -u2 "Expected one App Intents .xctestrun file in $products"
  exit 1
fi

if (( $# >= 3 )); then
  result_bundle=$3
  mkdir -p "${result_bundle:h}"
else
  result_directory=$(mktemp -d /private/tmp/sort-symphony-app-intents-result.XXXXXX)
  result_bundle=$result_directory/result.xcresult
fi
print "Result bundle: $result_bundle"
test_selection=()
if (( $# == 4 )); then
  test_selection=("-only-testing:$4")
fi
xcodebuild test-without-building \
  -xctestrun "$xctestrun[1]" \
  -destination "platform=iOS Simulator,id=$simulator_id" \
  -enableCodeCoverage YES \
  "${test_selection[@]}" \
  -resultBundlePath "$result_bundle"
