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
in explicitly (`automaticSchemesOptions: .enabled(codeCoverageEnabled: true)`). The aggregate
scheme still ignores that option by default. To get a coverage report from a full-suite run:

```sh
xcodebuild test -workspace "Sort Symphony.xcworkspace" -scheme "Sort Symphony" \
  -destination "platform=macOS,variant=Mac Catalyst" \
  -enableCodeCoverage YES --no-selective-testing
```

`--no-selective-testing` is required. Xcode's test-impact-analysis otherwise skips targets it
determines are unaffected, which under-reports coverage for anything not directly touched by the
diff under test.

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
