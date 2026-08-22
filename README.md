# Sort Symphony

[App Store](https://apps.apple.com/us/app/sort-symphony/id6477886990)

A sorting visualizer, inspired by the classic Sound of Sorting, written from the ground up for
Apple devices in Swift and SwiftUI.

## Features

- **167 sorting algorithms** and **46 shuffles**, spanning ArrayV's category taxonomy (exchange,
  hybrid, insertion, selection, merge, distribution, concurrent-simulated, and the deliberately
  impractical Bogo/Stooge/Slow family) — every one a native Swift implementation, not an
  interpreted script.
- **15 visualizer styles** (bar graph, rainbow, disparity family, circular/spiral/scatter/dot
  layouts, hoop stack, pixel mesh, and more), switchable live, mid-sort, with zero engine changes —
  the algorithm has no idea which style is currently drawing it.
- **GPU-rendered visuals** via a Metal renderer, with optional reduced-flashing/reduced-motion
  easing for photosensitivity.
- **Step, scrub, and seek** through any recorded sort, plus adjustable playback speed — a sort is
  recorded once, instantly, then replayed at whatever pace and resolution you want, independent of
  how long the algorithm actually took to run.
- **Showcase mode** auto-plays every algorithm in sequence; **size-sweep automation** re-runs one
  algorithm across its full supported array-size range — both useful for generating analytics data
  or just watching the whole catalog run unattended.
- **Sound**, generated per compared/swapped value through a small local synth (`ToneKit`, built on
  `AVAudioEngine`).
- **Operation counting** — compares, swaps, main-array writes, auxiliary-array writes, and
  reversals, all tracked per run.
- **Big-O correlation charts** (Swift Charts) plotting your own recorded runs against an
  algorithm's best/average/worst-case reference curves, synced across your devices via iCloud.
- **Per-algorithm reference material** — descriptions, time/space complexity with real math
  rendering, and syntax-highlighted code samples in 10 languages (C, C++, C#, Go, Java, JavaScript,
  Kotlin, Python, Ruby, Swift).
- Fully asynchronous, `@Observable`/Swift Concurrency-based implementation — no callback or
  delegate-based state management anywhere in the app.

## Requirements

- Xcode with an iOS 26 SDK or newer.
- Runs on iOS, iPadOS, and Mac Catalyst (no native macOS/AppKit target — see the
  [Architecture overview](Documentation/docs/architecture/overview.md#platform-and-scope-decisions)
  for why).
- [Tuist](https://tuist.dev) for project generation (see below).

## How to Build

This project is generated with [Tuist](https://tuist.dev) — there is no committed `.xcodeproj` to
open directly.

```sh
tuist install    # resolves Tuist/Package.swift's external dependencies
tuist generate   # produces Sort Symphony.xcworkspace
```

Then open `Sort Symphony.xcworkspace` in Xcode and run the `Sort Symphony` scheme, or stay on the
command line:

```sh
tuist build                                    # build everything
tuist test                                     # run every module's test suite
xcodebuild test -workspace "Sort Symphony.xcworkspace" \
  -scheme "SortEngineKit" -destination "platform=macOS,variant=Mac Catalyst"   # one module at a time
```

## Project Structure

The app is split into about 20 Tuist modules under `Modules/`, roughly in four layers:

- **Engine** — `SortEngineKit` (the record/replay tape engine), `AlgorithmKit` (algorithm/shuffle
  protocols + registries), `VisualizationKit` (the visualizer protocol + draw-command model),
  `ZstdKit` (a from-scratch Zstandard codec). No SwiftUI, no UIKit, minimal dependencies — the
  most-tested, least-churned layer.
- **Content** — `BuiltInAlgorithms` (every sorting algorithm and shuffle), `BuiltInVisualizers`
  (every visualization style). Adding one more of either is a new file in these modules, never a
  project-file edit.
- **Services** — `AudioEngineKit` and its supporting audio modules (`ToneKitDSP`,
  `ToneKitAVFoundation`, `SortAudioCore`, `SortAudioBridgeKit`, `SortAudioUnitKit`), `PersistenceKit`
  (analytics/CloudKit sync), `SettingsKit`, `DesignSystemKit` (shared UI components/themes),
  `MathRenderingKit` (complexity notation rendering).
- **Features** — `SortFeature` (the sort screen, run controls, Metal rendering host),
  `SettingsFeature`, `HomeFeature`, `IntentsKit` (Shortcuts/App Intents) — assembled together by the
  `Sort Symphony` app target.

For the full rationale behind this shape, including the places the app has since diverged from its
original design (most notably Metal rendering replacing `Canvas`, and a local synth replacing
AudioKit), see the [documentation site](Documentation/docs/index.md), or browse the source directly
under `Documentation/docs/`.
