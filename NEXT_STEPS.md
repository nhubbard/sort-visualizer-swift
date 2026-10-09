# Sort Symphony: focused next steps

Updated 2026-10-08. This list reflects the discussion after completing the native algorithm catalog and raising functional test coverage. The estimates describe engineering effort and review scope, not elapsed calendar time or a delivery commitment. They exclude waiting for other people or for a system reboot. Findings can change the implementation portion of an audit estimate.

## 1. Accessibility and Apple design-guidelines audit

**Why:** UI tests established identifiers, labels, and working controls, but they did not constitute a full assistive-technology or design review. The app should be understandable and operable with VoiceOver, large text, reduced motion, keyboard navigation, and its supported window sizes. The same pass should assess navigation, clarity, control placement, feedback, and information density against Apple's Human Interface Guidelines (HIG).

**Scope:**

- Treat Dynamic Type as the first gate: run Xcode's audit, inspect issues, and check the home and sort layouts at accessibility sizes before moving to lower-impact design polish.
- Walk the home, catalog, sort, settings, reference, chart, automation, tape import/export, and error journeys on iPad and Mac Catalyst. Include narrow and wide layouts, light and dark appearance, and an accessibility text size.
- Run Accessibility Inspector and Xcode's accessibility audit where supported. Manually check VoiceOver reading and focus order, actions, slider values, chart summaries, text clipping, contrast, Reduce Motion, and keyboard access. A passing automated audit does not replace the assistive-technology pass.
- Review each journey against the HIG's accessibility, layout, navigation, controls, toolbar, feedback, and onboarding guidance. Record a concrete issue, platform, reproduction, severity, proposed change, and verification method for each finding.
- Fix high-impact issues first, then rerun affected UI tests and the relevant manual journey. Keep aesthetic preferences distinct from broken or misleading behavior.

**Estimate:** source and guideline inventory 3–5 hours; iPad hands-on audit 6–10 hours; Catalyst hands-on audit 4–8 hours; findings and prioritization 3–5 hours; first batch of fixes and focused verification 1–3 days. Further fixes depend on findings. A brief optional review by interested coworkers can help assess clarity but is not a gate.

**Done when:** both platforms have a recorded issue list, each critical/high issue is fixed or explicitly scoped, and the affected journeys have been rechecked with the relevant assistive setting.

**Current progress:** The home title now runs a paced Quick Sort on every activation, with a stable spoken label and Dynamic Type layout. The sort canvas has a spoken summary, manual transport actions announce their result under VoiceOver, and the speed controls have spoken names and units. A focused Dynamic Type audit passed on Home and Sort. The sidebar clipping report and manual assistive-technology checks remain open; see [the audit log](Documentation/docs/guides/accessibility-design-audit-2026-10-06.md).

## 2. Refresh performance profiling, then use short InstrumentsKit traces

**Status:** Deferred at the owner's direction. Current performance is sufficient for this roadmap pass.

**Why:** Recent product and test changes justify a fresh representative trace. A broad trace can identify hot spots; the existing debug-only InstrumentsKit prototype can then capture very short, fast-to-analyze intervals. Avoid returning to hours of large trace analysis for every hypothesis.

**Scope:** capture a repeatable run that includes recording, playback, scrubbing, switching visualizers, and a large practical array. Compare main-thread and rendering behavior with earlier findings. After the user reboots into the permissive mode, use targeted micro-traces around identified hot spots; add signposts or a focused trigger only where the trace cannot isolate an interval. Verify each optimization with the same workload and a visual/playback sanity check. Keep InstrumentsKit isolated from ordinary app builds.

**Estimate:** workload and baseline 3–6 hours; broad capture and triage 4–8 hours; per hot spot, focused instrumentation/capture 2–5 hours and fix/verification from several hours to several days. Reboot and system configuration are external prerequisites.

**Done when:** the current baseline and top hot spots are recorded, and each changed path has before/after evidence. The existing prototype documents its current tape-generation trigger and the attached recording needed for interactive playback.

**Current baseline:** Four single-instrument traces, each under 30 seconds, are summarized in [the short-trace findings](Documentation/docs/guides/performance-traces-2026-10-06.md). The existing parent tape-generation wrapper is ready for focused InstrumentsKit runs after the permissive-mode reboot.

## 3. Contextual onboarding and discovery with TipKit

**Why:** Search, categories, and sorting already exist, but a new user still has to discover how to step, scrub, switch visualizers, and find a useful next algorithm. Contextual tips can explain an action at the moment it becomes relevant without adding a long mandatory tutorial.

**Scope:** choose a small set of first-use moments based on the design audit; define TipKit rules and events, display frequency, invalidation, and a way to revisit help. Start with playback controls, visualizer switching, and a related-algorithm suggestion. Test eligibility, dismissal, relaunch behavior, VoiceOver, and layouts. TipKit may introduce a comparison or teaching view, but does not implement either view.

**Estimate:** content and eligibility design 4–8 hours; integration 1–2 days; accessibility, state, and UI verification 1 day; polish after the design audit as needed.

**Done when:** tips appear only in their intended contexts, can be dismissed, do not obscure the task, and remain understandable without seeing the tip.

**Current progress:** Implemented across catalog discovery, playback, presentation, seeking, reference code, recorded charts, and Settings. The persistent How to Use sheet covers the same journeys. Focused iPad UI tests pass; see [the onboarding record](Documentation/docs/guides/tipkit-onboarding-2026-10-08.md).

## 4. Interactive teaching graph (original teaching-mode roadmap item)

**Status:** Quick Sort and Merge Sort pilot and algorithm-authored decision annotations implemented. See [the teaching graph record](Documentation/docs/guides/teaching-graph-pilot-2026-10-08.md) and [annotation design](Documentation/docs/guides/teaching-graph-annotations.md). Extending definitions to more algorithms, a fixed flowchart, and side-by-side comparison remain later work.

**Why:** A graph of decisions, movements, and dependencies could explain behavior more effectively than generic captions. The existing tape has operations and index markers, but no graph nodes, edges, or semantic relationships. This is a new teaching model, not a styling change.

**Scope:** define what nodes and edges mean for a small pilot covering contrasting algorithms, such as a quicksort partition and a merge. Link graph events to tape positions so stepping and seeking produce the same graph. Prototype a separate graph-event stream before changing `SortOperation` or the binary tape archive; consider how fast-playback compaction remaps event positions. Render readable focus and connection states, cap graph density, and provide an accessible textual account of each meaningful transition. Decide whether side-by-side comparison adds enough value after the pilot.

**Estimate:** visual/semantic model 1–2 days; engine-side event prototype and replay synchronization 2–4 days; graph UI and interaction 3–6 days; accessibility and verification 2–3 days. Extending it across the algorithm catalog is a separate, much larger content effort.

**Done when:** the pilot explains a complete run for each chosen algorithm, seeking reconstructs the correct graph, and a nonvisual user can follow the same meaningful transitions.

## 5. Live recording through ScreenCaptureKit (original video/GIF roadmap item, revised)

**Status (2026-10-08):** implemented live MP4 recording controls and backends. Catalyst 18.2+ uses ScreenCaptureKit's single-window picker with a ReplayKit fallback; iPadOS and older Catalyst use ReplayKit because the ScreenCaptureKit module is unavailable to the current iOS Simulator SDK. Preview, sharing, cancellation, errors, and interruption recovery are in place. Focused model tests compile; manual end-to-end capture and sharing on a signed device/host remain to verify. See [live recording verification](Documentation/docs/guides/live-recording-2026-10-08.md).

**Why:** Capturing actual playback may satisfy the sharing goal without building a separate off-screen renderer and fixed-frame-rate tape exporter. Apple's current framework is named **ScreenCaptureKit**.

**Scope:** verify the supported capture and save flow on the app's iPadOS and Mac Catalyst targets, including permission, picker, audio, stopping, and sharing. Decide whether to capture the full window or a selected app surface. Give the user clear recording state and recovery from denied permission or interruption. This produces a live recording; deterministic, arbitrarily paced export remains a different feature.

**Estimate:** platform/API spike 1–2 days; capture and save UI 2–4 days; cross-platform permission, audio, and interruption verification 1–3 days. Re-scope if the desired in-app capture behavior differs between platforms.

**Done when:** a user can start, stop, preview, and share a real recording on each supported target with an understandable permission flow.

## 6. CustomImage visualizer using image chunks (original roadmap item)

**Why:** A chosen image would make the existing permutation visualizer concept more personal. The 8,192 limit bounds sortable array items; it need not reject a source image with more than 8,192 pixels.

**Scope:** load and scale the source into a texture, then partition it into at most one chunk per sortable item. At each array position, display the chunk associated with that item's value. Specify the grid and any partial row so the sorted view reads as a coherent image. Define duplicate-value behavior explicitly: repeated values repeat a chunk unless item identity is added to the tape. Add picker, fallback, memory limits, and GPU texture-coordinate handling. Verify image orientation, aspect ratio, appearance, and switching during playback.

**Estimate:** chunk/duplicate design spike 4–8 hours; Metal renderer and texture handling 2–4 days; picker and state 1–2 days; boundary and playback verification 1–2 days. The image's pixel count mostly affects texture size and preprocessing, while array size governs chunk count.

**Done when:** an ordinary image is recognizable when sorted, permutes predictably during replay, and remains stable at the smallest and largest supported array sizes.

## Suggested order

The accessibility/design audit is nearing completion, contextual onboarding is implemented, and the teaching graph pilot is in place. Performance profiling is deferred. Prototype image chunks before committing to broad visualizer changes. Treat live recording as an independent sharing feature.

## References

- [Apple Human Interface Guidelines: Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [Apple Human Interface Guidelines: Design principles](https://developer.apple.com/design/human-interface-guidelines/design-principles)
- [Apple Human Interface Guidelines: Layout](https://developer.apple.com/design/human-interface-guidelines/layout)
- [Apple Human Interface Guidelines: Onboarding](https://developer.apple.com/design/human-interface-guidelines/onboarding)
- [Apple: Performing accessibility testing](https://developer.apple.com/documentation/accessibility/performing-accessibility-testing-for-your-app)
- [Apple: TipKit](https://developer.apple.com/documentation/tipkit/highlightingappfeatureswithtipkit)
- [Apple: ScreenCaptureKit](https://developer.apple.com/documentation/screencapturekit)
- [Project architecture history](Documentation/docs/architecture/history.md)
- [Existing Instruments prototype](Tools/InstrumentsPrototype/README.md)
