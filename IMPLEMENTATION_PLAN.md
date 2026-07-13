# Sort Symphony v2 — Implementation History

This was originally the ordered, phase-by-phase build plan for the v2 rewrite described in
`ARCHITECTURE_V2.md`. The rewrite is complete — every phase below shipped, `Legacy/` (the archived
pre-v2 source this plan built alongside) was removed once the migration finished, and the
repository is now entirely the v2 Tuist project. What follows is a short build history rather than
a plan; only **Phase 12 (stretch goals)** still has real, unbuilt content.

## Build history (Phases 0-11 — all shipped)

| Phase | Goal | Result |
|---|---|---|
| 0 | New branch, archive pre-v2 source to `Legacy/`, bootstrap the Tuist module graph empty | Done — `Legacy/` has since been removed entirely (Phase 11) |
| 1 | `SortEngineKit`: tape, `RecordingEngine`, `ReplayEngine`, unit-tested | Done |
| 2 | `AlgorithmKit` + one native algorithm (Quick Sort), proving record→replay end to end | Done |
| 3 | `ScriptingKit`: JS algorithm bridge, proven with Bubble Sort | Done, **later removed entirely** — every algorithm and shuffle is native Swift now, no scripting layer |
| 4 | `VisualizationKit` + first native visualizer (Bar Graph), first real `SortSession` screen | Done — rendering has since moved from `Canvas` to Metal, see `ARCHITECTURE_V2.md` §2A |
| 5 | Second/third visualizers, proving the visualization axis is genuinely orthogonal | Done — 14 visualizer styles ship today |
| 6 | Shuffles become tapes (`ShuffleAlgorithm`, concatenated shuffle+sort recording) | Done — ~38 shuffles ship today |
| 7 | Porting ArrayV content at scale (algorithms, shuffles, visualizations) | Done — ~82 algorithms, ~38 shuffles, 14 visualizers; CustomImage remains deferred (`ARCHITECTURE_V2.md` §2A) |
| 8 | Service decomposition: `AudioService`, `AnalyticsService` (CloudKit), `AppSettings` | Done — `AudioService`'s backend is `ToneKit` (a local AVAudioEngine synth), not AudioKit; AudioKit/AudioKitEX/SoundpipeAudioKit were later fully removed |
| 9 | Data-driven `ContentView`, real `SettingsFeature`/`HomeFeature` views | Done |
| 10 | Persistence finalization + complexity views | Done, with one scope change — the Swift Charts complexity-correlation view shipped (`BigOCorrelationChart.swift`, CloudKit-synced across your own devices) but never became its own `BenchmarkFeature` module; a separate device-to-device comparison view was dropped as a goal entirely (see `ARCHITECTURE_V2.md` §9) |
| 11 | Cleanup: remove `Legacy/` | Done — the repository is entirely the v2 module tree |

---

## Phase 12 — Stretch goals (still open)

Kept in sync with `ARCHITECTURE_V2.md` §2A, which has the full detail/opinion for each — this list
exists so Phase 12 is the one place tracking every open item, not a second, divergent copy of the
reasoning:

- **Teaching-mode step annotations** — visually indicating what a step *means*, not just that it
  happened. Deferred, not designed; real design work, not a quick addition.
- **Scriptable external automation** — driving the app from outside itself. Deferred, not designed;
  lean toward App Intents over AppleScript if this gets picked up (see `ARCHITECTURE_V2.md` §2A for
  why), but note it needs an "addressable current session" concept that doesn't exist yet.
- **Binary tape export/import for debugging a failed sort** — the more tractable of the deferred
  items, since `Tape` is already `Codable` and `ReplayEngine` already just consumes a plain `Tape`
  value.
- **Video/GIF export** — iterate a tape's operations off-screen through a `Visualizer` into
  `AVAssetWriter`. Not started.
- **CustomImage visualizer** — needs an image-picker UI and a per-pixel remap step. Deferred until
  the other 14 styles feel done and this specific novelty is worth the cost.

None of these block each other. Same commit discipline as the rest of this project's history: one
commit per item as it lands, not a grab-bag commit.
