# Short Instruments trace baseline

Recorded 2026-10-06 on Mac Catalyst, Xcode 27.0, macOS 27.0.1. Each trace used the **Blank** template plus exactly one instrument. The target was the Debug Sort Symphony process, running Ternary Quick Sort (LL) at 240 items. Traces are in `/private/tmp`; they are local working artifacts and are not part of the repository.

| Trace | Instrument | Workload | Size | Export |
| --- | --- | --- | ---: | --- |
| `/private/tmp/sort-time-profiler-20s.trace` | Time Profiler, 20 s | Enter Quick Sort, start a run, play, and open/switch the visualizer through computer use | 27 MB | `/private/tmp/sort-time-profile-20s.xml` |
| `/private/tmp/sort-playback-time-profiler-15s.trace` | Time Profiler, 15 s | Continuous Pixel Mesh replay, with no UI interaction during capture | 27 MB | `/private/tmp/sort-playback-time-profile-15s.xml` |
| `/private/tmp/sort-playback-hitches-15s.trace` | Hitches, 15 s | Continuous Pixel Mesh replay, with no UI interaction during capture | 21 MB | `/private/tmp/sort-playback-hitches.xml` |
| `/private/tmp/sort-visualizer-switch-hitches-18s.trace` | Hitches, 18 s | Replay and change from Pixel Mesh to Bar Graph through computer use | 21 MB | `/private/tmp/sort-visualizer-switch-hitches.xml` |

## What the samples show

- In the mixed 20-second trace, the largest app-owned stack was `CodeHighlighter.highlightRuns` under `AlgorithmDetailSection.highlightAllSamples`: **428 of 12,003** CPU samples (about 0.43 sampled CPU seconds). This is a cold algorithm-detail setup path. The existing code already runs it off the main actor and caches source/theme pairs, so these samples alone do not establish a UI stall.
- In the isolated 15-second playback trace, app-owned stacks were much smaller and distributed: `RunControlBar.body` appeared in **89 of 10,082** samples, `ReplayEngine.play` in **76**, and `MetalShapeRenderer.draw` in **75**. These are inclusive stack counts, not exclusive function times, and can overlap. No single app function dominated continuous playback.
- The playback Hitches trace found **one 8.33 ms delayed frame**. It contained 1,526 app-update records; median update duration was **2.02 ms**, and the 95th percentile was **3.02 ms**. The longest app update was **11.06 ms**, just before the delayed frame.
- The interactive visualizer trace found **three 8.33 ms delayed frames** and none longer. Computer-use accessibility inspection and menu interaction occurred during this recording, and there is no switch signpost in the trace. Those frames cannot yet be attributed to renderer construction.

These are observations from one algorithm, one size, and two visualizers. Time Profiler samples measure CPU activity; the Hitches instrument reports delayed frames. Neither establishes a catalog-wide sort ranking. The mixed trace includes computer-use accessibility work, which is why the playback-only trace is the better baseline for steady-state costs.

## Narrow follow-up after the permissive-mode reboot

InstrumentsKit remains disabled in ordinary builds. Its existing guarded `DebugInstrumentsTrace.run` call in `SortSession.start(size:)` already wraps `TapeFactory.makeTape` and supports repeated tape generation. Use that parent operation with **one profile at a time** to compare slow algorithms and shuffles without hours-long sweep traces.

1. Add an opt-in, debug-only trace boundary around `AlgorithmDetailSection.highlightAllSamples` or an individual `CodeHighlighter.highlight` miss. Label it with algorithm, language, and theme. Compare cold and cached visits; do not trace every highlight during normal use.
2. Put a short boundary around `MetalRendererView.Coordinator.switchVisualizerIfNeeded` and renderer creation/first reconciliation. Label old and new visualizer IDs. This will establish whether switching caused the measured delayed frames.
3. Reuse `ReplayEngine`'s existing `TickApply` and `TickDispatch` signpost intervals to separate tape mutation from renderer/audio callbacks. If either interval is consistently high, trace only that interval and then consider a narrower guard in the responsible code.
4. Keep individual captures below 30 seconds and inspect one instrument's export before adding another. Recheck with the same algorithm, size, visualizer, and speed when evaluating a fix.

No InstrumentsKit registration, linking, or runtime setting was changed in this baseline pass.
