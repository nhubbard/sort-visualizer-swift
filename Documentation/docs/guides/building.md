# Building the project

## Requirements

- Xcode with an iOS 26 SDK or newer.
- [Tuist](https://tuist.dev). This project is generated with Tuist. No committed
  `.xcodeproj`/`.xcworkspace` exists.

## Generate the workspace

```sh
tuist install    # resolves Tuist/Package.swift's external dependencies
tuist generate   # produces "Sort Symphony.xcworkspace"
```

Run `tuist install` again after any change to `Tuist/Package.swift` (a new or upgraded external
dependency). Run `tuist generate` again after any change to `Project.swift` (a new module, a new
target, a changed dependency edge), or when a new source file needs to be picked up by a cached
`glob` pattern.

Open `Sort Symphony.xcworkspace` in Xcode and run the `Sort Symphony` scheme. Or use the command
line:

```sh
tuist build      # build everything
tuist test       # run every module's test suite

# One module at a time:
xcodebuild test -workspace "Sort Symphony.xcworkspace" \
  -scheme "SortEngineKit" -destination "platform=macOS,variant=Mac Catalyst"
```

## Stale manifest cache

Tuist caches the parsed `Project.swift` manifest. If you add a file under a directory a
`.glob(pattern:)` scans in `Project.swift` — a new algorithm file, a new theme file, a new test
fixture — and Xcode does not pick it up after `tuist generate`, clear the manifest cache:

```sh
tuist clean manifests
tuist generate
```

## Coverage

Xcode does not gather code coverage by default; it is a real build-time cost. `Project.swift` opts
in explicitly (`automaticSchemesOptions: .enabled(codeCoverageEnabled: true)`). The generated
schemes can still ignore that option by default. To gather coverage for one Swift Testing unit
target:

```sh
xcodebuild test -workspace "Sort Symphony.xcworkspace" -scheme "SortEngineKit" \
  -destination "platform=macOS,variant=Mac Catalyst" \
  -enableCodeCoverage YES
```

Repeat with the other unit schemes to cover their modules. `Sort Symphony-Workspace` is the
aggregate scheme containing every unit and UI target; Xcode builds its UI runner even with
`-skip-testing`, so it can hit local Catalyst signing restrictions. The UI tests can run
separately on an iPad simulator. Find a device ID with
`xcodebuild -showdestinations -workspace "Sort Symphony.xcworkspace" -scheme "Sort SymphonyUITests"`,
then run:

```sh
xcodebuild test -workspace "Sort Symphony.xcworkspace" -scheme "Sort SymphonyUITests" \
  -destination "platform=iOS Simulator,id=<device-uuid>" \
  -enableCodeCoverage YES
```

The three `SortCommandsUITests` require a Mac Catalyst menu bar and skip on iPadOS. To run them
on Mac, use a local Apple Development identity and the test target's name (including its space)
in the `-only-testing` filter:

```sh
xcodebuild test -workspace "Sort Symphony.xcworkspace" -scheme "Sort SymphonyUITests" \
  -destination "platform=macOS,variant=Mac Catalyst" \
  -only-testing:"Sort SymphonyUITests/SortCommandsUITests" \
  -enableCodeCoverage YES CODE_SIGNING_ALLOWED=YES \
  CODE_SIGN_IDENTITY="Apple Development" DEVELOPMENT_TEAM=<your-team-id>
```

On the first run, macOS may ask you to approve the test runner and a separate UI automation
permission with Touch ID. The runner can launch but time out while enabling automation until that
second prompt is approved. `--no-selective-testing` is a Tuist flag, not an `xcodebuild` flag.
When using `tuist test` for coverage, pass `--no-selective-testing` to Tuist and pass
`-enableCodeCoverage YES` after `--`.

### App Intents integration tests

The `Sort SymphonyAppIntentsUITests` scheme uses Apple's `AppIntentsTesting` framework to run
Shortcuts actions through the system service. It runs on an iOS 27 iPad simulator while the app
itself retains its iOS 18 deployment target. Xcode 27 and an Apple Development signing identity
are required. Find the simulator ID with `xcrun simctl list devices available` and the identity
SHA-1 with `security find-identity -v -p codesigning`, then run:

```sh
Tools/AppIntentsTesting/run.sh <iOS-27-iPad-simulator-ID> <signing-identity-SHA-1>
```

The script builds the dedicated test scheme, signs the temporary simulator app and runner with
the same development identity, then runs the test bundle. Xcode's default ad hoc simulator
signatures cause App Intents' security service to reject these tests, so a plain `xcodebuild test`
for this scheme does not suffice. The regular `Sort SymphonyUITests` scheme remains available on
older simulators.

## Platforms

The app runs on iOS, iPadOS, and Mac Catalyst. It has no native macOS/AppKit destination, and none
is planned. See
[Architecture overview → Platform and scope decisions](../architecture/overview.md#platform-and-scope-decisions)
for the reason: `NSSlider` draws a visible tick mark per step on a stepped slider, which would
visibly break this app's stepped sliders. Mac Catalyst does not have this defect.

## Dev-tool Python environments

Several dev tools (`Tools/GrowthModelCalibration`, `Tools/SoundCoverageAudit`,
`Tools/GenerateThemes`, `App/Resources/AlgorithmDetails/manage.py`) are separate, `uv`-managed
Python projects, each with its own pinned `pyproject.toml`/`uv.lock`. None are part of the
Xcode/Tuist build. None run automatically. See their respective guides
([Recalibrating growth models](growth-model-calibration.md),
[Managing algorithm content](algorithm-content.md), [Dev tools](../reference/dev-tools.md)) for
usage.
