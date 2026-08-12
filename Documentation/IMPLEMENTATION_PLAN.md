# Sort Symphony v2 — Implementation History

This was originally the ordered, phase-by-phase build plan for the v2 rewrite described in
`ARCHITECTURE_V2.md`. The rewrite is complete — every phase below shipped, `Legacy/` (the archived
pre-v2 source this plan built alongside) was removed once the migration finished, and the
repository is now entirely the v2 Tuist project. What follows is a short build history rather than
a plan; only **Phase 12 (stretch goals)** still has real, unbuilt content.

## Build history (Phases 0-11 — all shipped)

| Phase | Goal                                                                                      | Result                                                                                                                                                                                                                                                                                                                  |
|-------|-------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 0     | New branch, archive pre-v2 source to `Legacy/`, bootstrap the Tuist module graph empty    | Done — `Legacy/` has since been removed entirely (Phase 11)                                                                                                                                                                                                                                                             |
| 1     | `SortEngineKit`: tape, `RecordingEngine`, `ReplayEngine`, unit-tested                     | Done                                                                                                                                                                                                                                                                                                                    |
| 2     | `AlgorithmKit` + one native algorithm (Quick Sort), proving record→replay end to end      | Done                                                                                                                                                                                                                                                                                                                    |
| 3     | `ScriptingKit`: JS algorithm bridge, proven with Bubble Sort                              | Done, **later removed entirely** — every algorithm and shuffle is native Swift now, no scripting layer                                                                                                                                                                                                                  |
| 4     | `VisualizationKit` + first native visualizer (Bar Graph), first real `SortSession` screen | Done — rendering has since moved from `Canvas` to Metal, see `ARCHITECTURE_V2.md` §2A                                                                                                                                                                                                                                   |
| 5     | Second/third visualizers, proving the visualization axis is genuinely orthogonal          | Done — 14 visualizer styles ship today                                                                                                                                                                                                                                                                                  |
| 6     | Shuffles become tapes (`ShuffleAlgorithm`, concatenated shuffle+sort recording)           | Done — ~38 shuffles ship today                                                                                                                                                                                                                                                                                          |
| 7     | Porting ArrayV content at scale (algorithms, shuffles, visualizations)                    | Done — ~82 algorithms, ~38 shuffles, 14 visualizers; CustomImage remains deferred (`ARCHITECTURE_V2.md` §2A)                                                                                                                                                                                                            |
| 8     | Service decomposition: `AudioService`, `AnalyticsService` (CloudKit), `AppSettings`       | Done — `AudioService`'s backend is `ToneKit` (a local AVAudioEngine synth), not AudioKit; AudioKit/AudioKitEX/SoundpipeAudioKit were later fully removed                                                                                                                                                                |
| 9     | Data-driven `ContentView`, real `SettingsFeature`/`HomeFeature` views                     | Done                                                                                                                                                                                                                                                                                                                    |
| 10    | Persistence finalization + complexity views                                               | Done, with one scope change — the Swift Charts complexity-correlation view shipped (`BigOCorrelationChart.swift`, CloudKit-synced across your own devices) but never became its own `BenchmarkFeature` module; a separate device-to-device comparison view was dropped as a goal entirely (see `ARCHITECTURE_V2.md` §9) |
| 11    | Cleanup: remove `Legacy/`                                                                 | Done — the repository is entirely the v2 module tree                                                                                                                                                                                                                                                                    |

---

## Phase 12 — Stretch goals (still open)

Kept in sync with `ARCHITECTURE_V2.md` §2A, which has the full detail/opinion for each — this list
exists so Phase 12 is the one place tracking every open item, not a second, divergent copy of the
reasoning. Ordered least to most effort, using the concrete seams named below and confirmed against
current code (`SortSession.swift`, `ReplayEngine.swift`, `RunControlBar.swift`). None of these block
each other, and each lands as its own commit as it's built, not a grab-bag.

**Shipped since this list was last updated: fixed-duration playback pacing.** Landed as a
user-facing pacing *mode* (`AppSettings.useFixedDurationPacing`/`targetPlaybackDuration`, an
alternative to the default ops/sec mode rather than a replacement for it — resolving this item's own
open question) with an adaptive per-tick deadline controller in `ReplayEngine` (recomputes the
required rate every tick from real remaining time and remaining significant work, rather than a
one-shot estimate) and an optional tape-compaction knob (`compactPlaybackForFixedDuration`, drops
only cosmetic mark/unmark bookkeeping — recorded stats are untouched either way). Applies uniformly
to manual, automated, and Showcase runs via `SortSession.startReplay`. See git history for the
commit.

**Also shipped: binary tape export/import.** Grew well beyond this item's original "for a failed
sort" scope on direct request — `SortSession.Phase.failed` never actually carries a `Tape` (checked
during design, not assumed), so export is a general, user-triggered action available whenever a
tape exists (`.ready`/`.replaying`/`.complete`), not failure-gated. Delivered in three commits:
(1) a real, from-scratch Swift Zstandard **encoder** for `ZstdKit` (previously decode-only) — a
greedy LZ77 match finder, FSE-coded sequences, Huffman-compressed literals — verified against a
real independent zstd implementation, which caught two bit-convention bugs self-round-trip alone
couldn't see (see `COMPRESSION_DESIGN.md`); (2) `Tape.archived()`/`Tape(archivedData:)`, a binary
archive format in `SortEngineKit` modeled on `AlgorithmDetails.algz`'s envelope but leaner (no
dictionary section), wrapping the new encoder around a payload that's a direct structural mirror of
`TapeHeader`'s 13 fields and `SortOperation`'s 12 cases; (3) UI wiring — an Export Tape `ShareLink`
button in `RunControlBar`, an Import Tape toolbar button routed through `SortCoordinator` (a new
`.loadTape` pending action, mirroring the existing App-Intents routing pattern) into
`SortSession.loadImportedTape(_:)`. See git history for the three commits.

1. **CustomImage visualizer** — Medium. Needs an image-picker UI (`PhotosPicker`, standard
   SwiftUI, low effort) and a per-pixel remap design (array value/index → pixel position — ArrayV's
   own "Custom Image" concept). `MetalShapeRenderer<Layout>` was already generalized across the
   other visualizer styles, so this becomes a 15th conformance following an established pattern
   rather than new rendering infrastructure. Deferred until the other 14 styles feel done and this
   specific novelty is worth the cost — a want-to-build-it-eventually item, not a blocked one.
2. **Video/GIF export** — Medium-Large. Iterate `tape.operations` off-screen at a fixed frame rate
   through whichever `Visualizer` is selected, into `ImageRenderer` → `AVAssetWriter` — reusing the
   same `VisualizationContext`/`draw(_:)` call the live UI already uses, driven by a loop instead of
   a display link, rather than a bespoke offscreen Metal texture pipeline. That reuse lowers risk,
   but this is genuinely unstarted (no `AVAssetWriter` usage anywhere in the repo today). Work: the
   off-screen drive loop, frame-rate/frame-count math for large tapes, `AVAssetWriter` plumbing
   (pixel buffer pool, video settings, session start/finish), and — only if true animated GIF is
   wanted — `ImageIO`'s `CGImageDestination` animated-GIF path as a second encoder. Recommend
   scoping the first pass to video-only to keep this Medium rather than Large.
3. **Teaching-mode step annotations** — Large. The engineering seam is small and already sketched:
   an optional `annotation: String?` (or a small "step intent" enum) riding alongside
   `SortOperation`, surfaced by opt-in `Visualizer`s as `DrawCommand.text` captions. The actual cost
   is content/design, not code — this needs a design pass at least as involved as `ARCHITECTURE_V2.md`
   itself, to design a vocabulary of step intents meaningful across ~82 different algorithms (a
   compare in quicksort means something different from a compare in radix sort). This is the only
   item where the blocker is design work, not implementation — recommend doing it last, and
   treating it as its own separate planning pass (prove the vocabulary on a handful of
   representative algorithms before rolling out to all 82) rather than folding it into a general
   "implement stretch goals" pass.
4. **MIDI-output Audio Unit** — Large. A second AUv3 extension target
   (`kAudioUnitType_MIDIProcessor`/`aumi`) alongside the existing audio-generating one
   (`App/AUv3Extension/`, `Modules/SortAudioUnitKit/` — see `AUDIO_UNIT_PLAN.md`) — genuinely
   parallel work, not an extension of it: its own principal class/registration, and a render path
   emitting `MIDIEventList`s instead of audio samples. The payoff is real — it routes the same
   sort-to-tone semantics (`SortAudioCore`) into *any* synth plugin a host has loaded, not just this
   app's own built-in oscillator+envelope, which is a genuinely different value proposition than the
   audio-bridge AU (more sonic variety via other people's instruments, vs. hearing this app's own
   voice inside a DAW's effects chain). Would need its own note-mapping layer, comparable to but
   distinct from `SortAudioBridgeKit`'s existing audio-event wire format — ideally sharing whichever
   value-to-pitch logic (e.g. scale quantization) the richer-local-synthesis work below lands on,
   rather than being designed in isolation. Supersedes an earlier, smaller-scoped idea noted in
   `ARCHITECTURE_V2.md` (a plain CoreMIDI virtual-source output, itself a rescoped-down version of a
   full customizable-synth-playground pitch) — now that real AU-hosting infrastructure exists, an
   AU-hosted MIDI generator is arguably the more natural fit than a bare system-wide virtual MIDI
   port would have been. Not scheduled; best picked up after the local-synthesis richness work
   (scale quantization, stereo panning, compare/swap timbral differentiation) has shipped, since that
   work will settle the pitch-mapping vocabulary this would want to reuse.
