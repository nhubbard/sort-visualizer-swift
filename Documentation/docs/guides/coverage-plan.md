# Functional coverage plan

## Goal and scope

Make the automated suite the release authority for functional behavior on iPadOS and Mac Catalyst.
Reserve manual review for the appearance and feel of visualizations, especially animation
and unusual inputs. A coverage percentage is a gap-finding measure, not evidence that a behavior is
correct; every important user journey also needs an assertion about its outcome.

This plan covers the app, its modules, the Mac Catalyst AUv3 extension, and system integrations.
Third-party packages, generated Tuist code, test targets, and unreachable platform branches must
not inflate or depress the app-owned coverage metric. Report the AUv3 extension and platform-only
code separately so neither disappears from the denominator. Keep the app's current deployment
target; the App Intents system tests can continue running on an iOS 27 simulator.

## Current evidence and measurement limits

- The existing corpus contains Swift Testing suites across the engine, algorithms, visualizers,
  services, audio, and features, plus XCTest UI suites. Algorithm correctness and stability,
  replay, archive, audio, persistence, and Metal renderer behavior already have focused tests.
- The [2026-10-02 source-verified baseline](../../../Tools/TestCoverage/baselines/2026-10-02/README.md)
  combines 19 passing Mac Catalyst module suites, the passing iPad UI suite, the passing iOS 27
  App Intents suite, and the passing Mac Catalyst UI suite: 34,995/36,785 measured app-owned
  source lines (95.13%). The 22 bundles contain 755 passing tests and 11 platform skips. Of 63
  changed executable lines relative to `HEAD`, 58 are covered (92.06%).
  Sixteen production Swift files have no coverage record, including both AUv3 extension UI files;
  the measured aggregate is therefore not a claim of complete extension coverage.
- The App Intents system suite has thirteen passing tests for registration, queries, settings,
  stopping while idle, a complete visible sort, both automation modes, a live sound-setting
  change, default size changes, and rejection of an unknown algorithm and idle size cycling.
  Other error paths still need system-level coverage.
- The full Mac Catalyst UI suite passes 23 tests with two platform skips. It includes native
  settings persistence, transport and keyboard controls, visualizer switching, a real tape save
  and import after relaunch, and a corrupt-tape error that can be dismissed. Xcode omits
  `Metadata.plist` from the Catalyst UI coverage archive, so this suite is behavioral evidence
  without attributable line coverage. Its import callback is the five-line changed-code gap.
- iPad UI tests prove native export/import panel presentation; the archive and coordinator suites
  prove the data path. A complete native iPad save/import round trip remains untested.
- The settled-pixel baseline covers all 15 current Metal visualizers in one deterministic scene.
  It does not cover the visual input matrix or the animation path.

Do not add percentages from different test runs or count third-party targets in an app-owned total.

## Workstreams 1 and 3 implementation status

The runner and report generator under `Tools/TestCoverage/` now create a source hash snapshot,
retain each result bundle, verify passed test summaries, merge covered source-line identities, and
publish per-platform, per-target, per-file, changed-line, and unmeasured-source views. The report
rejects a missing coverage archive unless the lane is explicitly declared behavioral-only. Its
merger has fixture tests for line union, platform separation, stale sources, and invalid bundles.

The highest-risk journeys now have a Catalyst tape save/import/replay test, a visible corrupt-file
error test, a tape archive/session replay integration test, thirteen iOS 27 App Intents system
tests, and a passing full Catalyst UI suite. Settings persistence and reset, run controls,
keyboard commands, and visualizer switching run on Catalyst as well as their applicable iPad
checks. The remaining Workstream 3 gaps are a complete native iPad tape round trip; additional
system-intent error/busy cases; a host test for the AUv3 parameter view and controller; and
signed-in CloudKit and external AU host canaries. The current combined line coverage exceeds its
90% floor, but SortFeature (87.85%), IntentsKit (61.91%), and the app target (77.53%) remain
below the per-target floor, while the AUv3 UI sources remain unmeasured.

## Definition of done

The functional-manual-QA retirement gate is met when all of the following hold:

1. Every supported user journey in the contract matrix below has an automated positive case, a
   meaningful edge or failure case, and assertions on the final state. A test that only checks
   whether a button or system panel appears does not close a journey.
2. The required platform matrix passes from a clean generated workspace, with no unexplained
   skips, flaky retries, or known failing tests. Platform-inapplicable cases are declared in the
   matrix rather than silently skipped.
3. A repeatable report shows at least 90% **combined app-owned executable-line coverage**, at
   least 90% in each testable feature/module with substantial behavior, and at least 95% in the
   recording/replay, archive, algorithm, audio DSP, and bridge components. Changed executable
   lines are at least 90% covered or have a documented reason. These thresholds are floors, not
   reasons to add tests that repeat implementation details.
4. Fault-injection or mutation probes show that key tests fail when sorting, replay, persistence,
   intent routing, or audio transport deliberately returns the wrong result. Archive corruption,
   recording-cap, cancellation, and unavailable-service cases have direct assertions.
5. External integrations that cannot run deterministically on a simulator have an automated
   component/host test and a scripted canary on the relevant device or host. Any remaining
   unscripted functional check is listed as an explicit release exception, not counted as covered.
6. A short visual review remains for appearance, legibility, and animation quality. Deterministic
   pixel and geometry tests narrow the combinations that need human inspection.

The thresholds are targets to validate after the measurement work. If a platform or system service
cannot attribute its execution to source lines, keep its behavioral test as a separate required
gate rather than lowering the quality requirement or fabricating a combined number.

## Workstream 1: trustworthy coverage reporting

**First deliverable:** a `Tools/` coverage runner and report generator, plus a baseline report
committed or attached to the change that introduces it.

1. Pin the Xcode version, simulator runtime/device IDs, Tuist version, and source revision in the
   report. Regenerate the workspace when manifests or discovered files change.
2. Run module suites with coverage, the iPad UI suite, the iOS 27 App Intents system suite, and
   the Mac Catalyst UI/extension lanes separately. Save each `.xcresult` and its test summary.
3. Extract per-file executable and covered **line identities** from each valid result bundle.
   Union covered lines only for matching normalized source files and matching source revisions;
   never add counts or percentages. Keep separate platform reports where compiler conditions
   change the executable-line universe.
4. Classify app-owned files by target and platform. Exclude test files, generated build output,
   third-party packages, and tooling from the production denominator. Publish per-target totals,
   uncovered functions/lines, changed-line coverage, and a list of tests/results that contributed.
5. Validate the merger against a small known file and against Xcode's own single-result totals.
   Fail the report if an `.xcresult` is missing coverage metadata, as happened in the Catalyst
   command run; do not quietly treat it as zero coverage or as a valid empty report.

**Exit:** one command yields an auditable baseline and identifies the largest *reachable* gaps.
This workstream decides which later coverage targets are meaningful.

## Workstream 2: functional contract matrix

The [versioned functional contract matrix](functional-contract-matrix.md) tracks each observable
outcome, production owner, test layer, required platform, passing result-bundle lane, current
evidence, and the next assertion needed to close a partial or open contract. Update it with every
feature change; the table below is the top-level scope checklist.

Maintain a versioned table mapping each contract to its owner, test layer, platforms, and result
bundle. Start with the contracts below; add a row for each newly discovered user-facing branch.

| Contract | Main automated evidence to add or strengthen | Required platforms |
| --- | --- | --- |
| Algorithm/shuffle catalog | Registry completeness; every built-in sort/shuffle preserves its required invariants over empty, tiny, random, duplicate-heavy, sorted, reversed, and boundary-size inputs; reproducible seeds and stability where promised | Unit on Catalyst; UI sample on iPad |
| Recording and replay | Tape operations match final values and counters; stepping, seeking, reset, pause/resume, completion, operation cap, malformed tape, and cancellation preserve state | Unit on Catalyst; UI on iPad |
| Sort session and automation | Selected algorithm/shuffle/size/visualizer reach the expected state; all automation modes advance, stop, recover from failure, and preserve resumable Full Sweep logs | Unit on Catalyst; UI on iPad and Catalyst |
| Settings and launch | Changes persist across a fresh launch; defaults restore; invalid stored IDs/values recover; controls reflect current state | Unit plus UI on iPad and Catalyst |
| Tape export/import | A saved tape can be imported by a fresh session with matching metadata and replay; corrupt/unsupported files produce a visible recoverable error | Document/coordinator integration; one UI round trip per native platform family |
| App Intents | System resolves entities and parameters, executes run/automation/playback/settings actions, reports errors, and leaves the visible app in the expected state | iOS 27 AppIntentsTesting; direct unit tests for app logic |
| History and sync | Exactly one completed run is recorded; interrupted runs are not; local read/write/query, migration/error behavior, and CloudKit configuration are verified | SwiftData integration; scripted signed-in-device sync canary |
| Audio and AUv3 | Offline samples and routing are correct; bridge reconnect/fallback works; AU parameter edits reach the audio unit and observer updates reach the view | Catalyst unit/host tests; scripted AU host canary |
| Visualizer selection | Every registered visualizer renders finite in-bounds geometry and survives switching during replay; deterministic settled pixels and key transition frames match reviewed baselines | Metal tests on supported GPU families; UI on iPad/Catalyst |
| Navigation and accessibility | Sidebar, detail, settings, keyboard commands, orientation, Dynamic Type, VoiceOver labels/actions, and empty/error states remain operable | iPad and Catalyst UI suites |

Use a small number of end-to-end UI tests to verify wiring, then assert most combinations at the
module or integration layer. For example, the algorithm corpus belongs in fast headless tests;
the UI only needs representative sorts that prove a recording becomes a playable visible result.

## Workstream 3: close the highest-risk journeys

Complete these in order, recording a passing result and the relevant coverage delta after each:

1. **Tape lifecycle:** Test `TapeArchiveDocument` serialization/deserialization and errors, then
   a real save/import flow on iPad and Catalyst (or a stable in-app test fixture entry point that
   exercises the same document and coordinator path). Assert replayed values and metadata after
   import, not merely that the picker appeared. Avoid reliance on changing system-sheet labels.
2. **Intent execution:** Extend the iOS 27 system tests to run a sort, start/stop each automation
   mode, exercise playback and sound/settings actions, and verify visible/coordinator state.
   Include invalid entity, unsupported size, busy/idle, and repeated invocation cases. Keep
   direct `perform()` unit tests for errors the system harness cannot inject.
3. **Catalyst flows:** Make shared UI setup platform-aware, then run the applicable navigation,
   settings, transport, import/export, and visualizer-switch tests on Catalyst. Keep menu/keyboard
   tests Catalyst-only and orientation tests on iPad. Fix product failures before broadening
   assertions. Tuist targets `.iPad` and `.macCatalyst`; iPhone is outside the current product scope.
4. **AUv3 extension UI:** Add a minimal hostable test target or harness for the actual parameter
   view/controller and unit tree. Verify parameter-to-view and view-to-parameter updates,
   disconnect/reconnect, invalid values, and observer cleanup. Keep a scripted host canary for
   third-party DAW loading and audible route selection.
5. **Persistence and failures:** Test settings and analytics across relaunch with isolated stores;
   verify completion-only analytics, duplicate prevention, store failure, malformed persisted
   values, CloudKit configuration, and a signed-in-device sync canary.

## Workstream 4: test strength and visual automation

- Keep the broad seeded algorithm corpus. Save failing seeds and minimize failures so they become
  permanent regression cases. Verify the engine access audit after algorithm edits.
- Add property tests for record/replay equivalence and archive round trips, including auxiliary
  operations and cap boundaries. Compare against independent oracles such as Swift sorting and
  direct state reconstruction, not the same helper used by production code.
- Use deliberate, temporary defects to check that the critical tests detect wrong ordering,
  skipped replay operations, incorrect saved fields, misrouted intents, and silent audio fallback.
  Record the probe and restore production code before merging.
- Expand Metal baselines with a small pairwise matrix: tiny/large and duplicate-heavy inputs,
  sorted/reversed/permuted states, markers, light/dark appearance, scale, and accessibility text
  size where relevant. Include a few fixed transition timestamps in addition to settled frames.
  Review and version baseline updates deliberately; avoid treating a changed hash as automatic
  approval of a visual change.
- Test accessibility behavior as functionality: labels, adjustable controls, focus order where
  stable, and keyboard access. Human visual review still judges clarity and motion.

## Required execution lanes

| Lane | When | Contents | Gate |
| --- | --- | --- | --- |
| Fast local/PR | Each change | Affected module suites, algorithm/engine audit when relevant, a small iPad UI smoke set, changed-line report | All tests pass; no unexplained coverage regression |
| Full simulator | Nightly and before release | All module suites; iPad UI; iOS 27 App Intents system suite; deterministic Metal matrix; seeded corpus | Contract matrix green; coverage floors met |
| Mac Catalyst | Nightly and before release | Applicable full UI suite, command/keyboard suite, audio bridge and AUv3 host tests | All applicable tests pass; coverage archive valid |
| External canaries | Before release and after integration changes | Signed-in CloudKit sync and AUv3 host/routing checks on configured hardware | Scripted result and logs attached; exceptions documented |
| Visual review | Before release and after renderer/UI changes | Curated input matrix on representative screen sizes and appearance settings | Human approval for appearance and animation |

The repository currently documents local Tuist/Xcode commands and has no checked-in CI workflow.
Make the local runner reproducible first; then wire the same commands into CI on capable macOS
hosts. Keep signing identities and device-specific prerequisites out of the repository.

## Reporting and prioritization rules

For each work item, record the failing or missing contract, new test, result bundle, coverage
change, and any remaining platform limitation. Prioritize uncovered behavior by user impact and
failure likelihood: data integrity and incorrect sort/replay results first, then external action
routing and persistence, then UI control wiring, then purely presentational branches. Do not
increase line coverage by moving code, excluding real app-owned files, or adding assertions that
would still pass for an incorrect outcome.

When the definition of done is met, routine release QA can rely on these automated lanes for
functional behavior. Reopen manual functional checks only for a documented platform limitation,
a newly discovered failure mode, or a changed external service contract.
