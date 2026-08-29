---
icon: lucide/rocket
---

# Sort Symphony

Sort Symphony is a sorting-algorithm visualizer for iOS, iPadOS, and Mac Catalyst. Swift and
SwiftUI implement the entire app natively. The design draws on the classic
[Sound of Sorting](https://panthema.net/2013/sound-of-sorting/) project.

This site documents the app's architecture and extension points. For the app itself, see the
[App Store listing](https://apps.apple.com/us/app/sort-symphony/id6477886990).

## Capabilities

- **167 sorting algorithms** and **44 shuffles**, covering
  [ArrayV](https://github.com/gouravkhunger/ArrayV)'s category taxonomy: exchange, hybrid,
  insertion, selection, merge, distribution, concurrent-simulated, and the intentionally
  impractical Bogo/Stooge/Slow family. Every algorithm is native Swift, not an interpreted script.
- **15 visualizer styles**, from a bar graph to disparity plots, spirals, scatter and dot layouts,
  a hoop stack, a pixel mesh, and a Hanoi-towers layout. The app switches styles live, mid-sort,
  with no engine changes, because the algorithm has no visibility into which visualizer is active.
- A Metal renderer with optional reduced-flashing and reduced-motion easing for photosensitivity.
- Step, scrub, and seek controls for any recorded sort, plus adjustable playback speed. The app
  records a sort once, then replays it at any pace, independent of the algorithm's actual run time.
- Showcase mode, which plays every algorithm in sequence. Size-sweep automation, which re-runs one
  algorithm across its full supported array-size range.
- Sound generation per compared or swapped value, through a local synth (`ToneKit`, built on
  `AVAudioEngine`). On Mac Catalyst, a bundled Audio Unit extension relays this audio into a DAW.
- Operation counting for compares, swaps, main-array writes, auxiliary-array writes, and reversals,
  tracked per run.
- Big-O correlation charts (Swift Charts) that plot recorded runs against an algorithm's
  best/average/worst-case reference curves. iCloud syncs this data across devices.
- Per-algorithm reference material: descriptions, time and space complexity with math rendering,
  and syntax-highlighted code samples in ten languages (C, C++, C#, Go, Java, JavaScript, Kotlin,
  Python, Ruby, Swift).
- An asynchronous implementation built on `@Observable` and Swift Concurrency. The app contains no
  callback- or delegate-based state management.

## Where to start

- **To understand the architecture**: read [Architecture → Overview](architecture/overview.md)
  first. It covers the record-now, replay-later split that the rest of the app builds on. Then
  read the layer pages in order: [Engine](architecture/engine.md),
  [Content](architecture/content.md), [Audio](architecture/audio.md),
  [Services](architecture/services.md), [Features](architecture/features.md).
- **To make a specific change**: go directly to a [guide](guides/building.md). Guides cover adding
  an algorithm, a shuffle, or a visualizer; recalibrating growth models; and regenerating the
  packed algorithm-content archive.
- **To look up a byte-level format or a dev tool's flags**: see
  [Reference](reference/compression.md).

## Requirements

- Xcode with an iOS 26 SDK or newer.
- iOS, iPadOS, or Mac Catalyst. There's no native macOS/AppKit target; see
  [Architecture overview → Platform and scope decisions](architecture/overview.md#platform-and-scope-decisions)
  for the reason.
- [Tuist](https://tuist.dev) for project generation; see [Building the project](guides/building.md).

## Module layers

The app splits into about 20 Tuist modules under `Modules/`, organized into four layers.

| Layer | Modules | Responsibility |
|---|---|---|
| Engine | `SortEngineKit`, `AlgorithmKit`, `VisualizationKit`, `ZstdKit` | The record/replay tape engine, the algorithm/shuffle/visualizer protocols and registries, and a Zstandard codec. No SwiftUI, no UIKit. |
| Content | `BuiltInAlgorithms`, `BuiltInVisualizers` | Every sorting algorithm, shuffle, and visualization style. |
| Services | `AudioEngineKit` and its supporting audio modules, `PersistenceKit`, `SettingsKit`, `DesignSystemKit`, `MathRenderingKit` | The local synth and its Audio Unit relay, analytics and CloudKit sync, user settings, shared UI components and themes, complexity-notation rendering. |
| Features | `SortFeature`, `SettingsFeature`, `HomeFeature`, `IntentsKit` | The sort screen, the Metal rendering host, the settings screen, the home screen, and the Shortcuts/App Intents surface. |

Each layer has its own page under [Architecture](architecture/overview.md). For build history, see
[History](architecture/history.md).
