# Instruments private framework experiment — running log

Last updated: 2026-09-20 (macOS 27.0, Xcode 27.0 / 27A266a)

## Expansion in progress (2026-09-20)

- Added a resumable compatibility harness with 5,398 finite cases when all
  Boolean combinations are requested: baseline templates, individual
  instruments, template additions, instrument pairs, and option variants.
  The complete baseline ran: 25 templates and 63 individual instruments.
  Their exported runs identified two platform-only templates (Power
  Profiler and RealityKit Trace) and five platform-only instruments (Core
  Animation FPS, Foveated Streaming Statistics, Power Profiler, RealityKit
  Frames, RealityKit Metrics). Generated `MacCompatibility.json` and a Swift
  filter from those explicit run issues. The public macOS `TraceTemplate`
  enum no longer offers the two platform-only templates; `.named` and added
  instrument validation also consult the generated filter. The Swift library
  builds with that filter. CPU Counters added alone to Blank produced “No
  counting mode selected,” while HTTP Traffic stopped at a privacy warning,
  and `stdout/stderr` lacks the private attached-process target capability.
  Processor Trace's standard template timed out in this CLI sweep; its
  individual-instrument CLI case was valid, but the private wrapper still
  fails to stop it reliably. These statuses are distinct in the result file.
  No TCC denial occurred.

- Exercised 10 template additions, five instrument pairs, and five Boolean
  option variants. The additions included the same CPU Counters counting-mode
  error on Activity Monitor; eight additions saved valid traces, one was an
  existing instrument, and all five pairs and five option variants exported.
  Each harness case removed its temporary trace and CPU fixture after export.
  The full 5,398-case matrix remains runnable and resumable but has not yet
  been executed end to end; numeric ranges and groups of three or more
  added instruments are outside this finite matrix. Privacy-sensitive
  recorders are skipped by default. The harness now derives obvious platform
  failures in combination cases from baseline evidence instead of starting
  those doomed recordings, while retaining a separate derived status.

- Expanded the app's opt-in trace picker and loopback host from five to
  twelve profiles: added Allocations, Leaks, Swift Concurrency, SwiftUI,
  Logging, System Trace, and Data Persistence. Each added profile completed
  through the injected private-framework recorder with `READY`/`STOP`/`DONE`
  and an exportable table of contents. The seven test traces, host process,
  and fixture were removed by the disposable test harness. No run issue or
  TCC denial appeared. The full Mac Catalyst Debug `SortSymphony` scheme
  built with `LOCAL_INSTRUMENTS_TRACING`. An initial build used the display
  name `Sort Symphony` as a scheme and failed immediately; workspace listing
  showed the actual scheme is `SortSymphony`. The successful build emitted
  pre-existing missing Metal toolchain search-path and other source warnings.

- Added a private runtime target-capability check after template composition
  and before starting a trace. The bridge now returns typed
  `targetUnsupported` (status 15) and removes its output directory when the
  selected instruments reject the requested process target type. An injected
  CPU Profiler plus `stdout/stderr` check reached this exact rejection for
  attached target type 2, with no leftover trace. This confirms the catalog's
  earlier static finding and prevents a misleading successful start attempt.
  The probe printed the recurring Launch Services assertion but no TCC
  denial. Added task cancellation to `recordAsync`: it requests an early stop
  at the next private recorder poll, removes partial output, and throws typed
  `RecordingError.cancelled`. A live ten-second CPU Profiler async request was
  cancelled after two seconds in the signed carrier. It reported `started`,
  stopped and saved without a run issue, then surfaced the typed cancellation
  error and removed the partial trace. The expected framework package lookup
  thread warnings and Launch Services assertion appeared; no TCC denial did.

- Expanded `TraceInstrument` to sixteen named instrument IDs with verified
  individual baseline recordings. Generated a template-composition map from
  `TemplateComposition.json`, and the plan validator now rejects any added
  instrument already in the selected template. A linked Swift consumer
  rejected CPU Profiler plus duplicate Points of Interest, rejected the
  `.named("Power Profiler")` macOS escape, and accepted Activity Monitor plus
  an added Hangs instrument with a typed 33 ms setting. A real injected
  Activity Monitor plus Hangs trace applied the native Hangs options after
  insertion, started, stopped, and exported Hangs schemas with zero run
  issues. The trace was removed. The export establishes that the setting
  setter ran and the Hangs instrument was present; it does not prove the
  exact threshold value in the saved archive.

- Ran 50 more single-field option variants through the bounded CLI harness.
  The cumulative survey now has 158 distinct completed cases of the 5,398
  finite full-matrix cases: 131 valid, 11 valid with warnings, seven explicit
  platform failures, three privacy skips, two recording errors, one privacy
  prompt, one unsupported attached target, one duplicate, and one timeout.
  Eight of the new option variants reported nonfatal `time-sample` binding
  warnings where requested and configured sampling periods differed. These
  appeared when flipping Time Profiler options inside Animation Hitches, App
  Launch, CPU Counters, and Game Performance; the exact settings and warning
  text are preserved in `CompatibilityResults.jsonl`. They are not yet proven
  to be private-recorder failures, so the validator does not reject them.
  The harness work directory was empty after the batch; no TCC denial arose.

- Added `package.sh` to export the experimental library, bridge, build script,
  compatibility catalogs, and documentation as a self-contained source
  archive. Extracted that archive under `/private/tmp` outside the repository
  and successfully built its Swift dynamic library and module with a separate
  build directory. Deleted the temporary archive and extraction afterward.
  The loopback host now has a ten-second initial request timeout, loops until
  each reply is sent, and appends a UUID fragment to trace names to prevent
  same-millisecond collisions. The library builds after these changes.

- Completed all 128 single-field Boolean and numeric-sample option cases.
  Latest outcomes: 92 valid, 18 valid with warnings, 12 derived platform
  skips, one privacy skip, and five Processor Trace timeouts. SwiftUI's
  warnings said the CPU-only fixture produced no SwiftUI data; other warnings
  were sampling-period mismatches in Time Profiler tables. Retried all five
  Processor Trace timeouts: four timed out again, while one first reported
  `_lockKPerf: could not lock kperf. Likely another session just started.`
  and then timed out on a further retry. `ps` showed no leftover `xctrace`
  or fixture process, only the existing `DTServiceHub` and `tailspind`; a
  fresh CPU Profiler control trace then exported validly. This is a
  Processor Trace or service lifecycle anomaly, not evidence of a global
  profiling permission failure. No TCC denial occurred. Added
  `--only-template` to make targeted reruns easier. All case traces were
  removed.

- Continued the template-plus-instrument matrix by 100 cases. Activity
  Monitor now has all 63 possible one-instrument additions classified:
  50 valid, one valid with the CPU fixture's no-SwiftUI-data warning, two
  duplicates, five derived platform failures, two privacy skips, CPU Counters
  missing its counting mode, Processor Trace timeout, and `stdout/stderr`
  rejecting attached-process target type 2. The Allocations template reached
  47 of 63 additions; it showed the same CPU Counters and Processor Trace
  problems, plus known platform/privacy/duplicate cases. Overall the finite
  5,398-case matrix has 331 completed distinct cases. All temporary traces
  and the fixture were removed; the harness work directory is empty. No new
  TCC or permission denial appeared.

- Began a cross-template ordered addition sweep to expose interactions by
  instrument. Audio System Trace plus Advanced Graphics Statistics produced
  a hard run issue: “This instrument doesn't support Windowed Mode.” The
  selected Audio template archive has a five-second `windowLimit`; its stored
  `recordingMode` is still Deferred (`2`). This is a mode/composition conflict,
  separate from macOS platform exclusion or TCC, and will need a typed
  recorder-window invariant once the exact private setter is verified.

- Cross-template CPU Counters additions have now failed on 20 tested parent
  templates with the identical preflight issue “No counting mode selected”
  (plus its CPU Bottlenecks recovery suggestion). The CPU Counters standard
  template itself remains valid. This supports a general configuration
  prerequisite rather than a pair-specific platform exclusion. Animation
  Hitches plus an added CPU Profiler then failed with “Data source agent failed
  to setup” and a suggestion to remove CPU Counters, even though that
  composition did not add CPU Counters. This odd diagnostic requires a clean
  retry before it becomes a declarative incompatibility rule. No TCC error
  appeared.

- Resolved the observed Windowed Mode pair errors without changing installed
  Xcode templates. A disposable copy of Audio System Trace patched from
  `windowLimit = 5_000_000_000` to `0` recorded with Advanced Graphics
  Statistics, zero run issues, and an exported `graphics-statistic` schema.
  Added typed `TraceSetting.captureLast(.disabled | .last(Duration))`, generated
  the selected template's window capability set, and made plan validation
  permit those previously rejected pairs only when the window is disabled.
  The typed path recorded both Audio System Trace and Game Performance plus
  Advanced Graphics Statistics with valid exports. A one-second typed Capture
  Last selection saved `windowLimit = 1_000_000_000`, confirming nanoseconds.
  The Game Performance test printed `DTXMessage _appendTypesAndValues:
  unknown parameter type` lines, but its run issue count was zero and the
  trace exported. No TCC denial occurred. Removed all temporary trace bundles
  and copied templates after inspection.

- A typed Core Animation Commits setting now validates the decoder-accepted
  sampling levels `0...2`. A private Activity Monitor plus Core Animation
  Commits run with level `1` saved `{"expensiveCommitSampling":1}` in
  `form.template` and exported three Core Animation Commits schemas with zero
  run issues. The temporary trace was removed.

- Finished 250 cross-template ordered addition cases, bringing the durable
  survey to 581 of 5,398 finite cases. The 360 template-addition outcomes so
  far are 232 valid, 19 valid with warnings, 12 duplicates, 32 derived
  platform failures, 26 privacy skips, 27 hard recording errors, 11 timeouts,
  and one unsupported attached target. Five added-CPU-Profiler pairs failed
  with data-source or KPC binding errors; all five failed identically in a
  targeted second run. The generated catalog now keeps these repeatable hard
  pairs separate from the two Windowed Mode pairs. The validator rejects the
  hard pairs regardless of settings and permits the Windowed pairs only with
  `.captureLast(.disabled)`. No temporary trace or fixture remained after the
  sweep and retries. No TCC denial appeared.

- A linked Swift consumer check confirmed the new validation boundaries:
  stock Audio plus Advanced Graphics Statistics fails; explicit Capture Last
  disabled accepts both Audio and Game Performance plus Graphics; SwiftUI
  plus CPU Profiler remains rejected even with the window disabled;
  Allocations rejects Capture Last because its archive does not support it;
  and an Immediate plus Capture Last duration combination is rejected.

- Started another 500-case cross-template addition batch after the 581-case
  checkpoint. Results append to `CompatibilityResults.jsonl` after each case;
  this entry is intentionally an in-progress checkpoint. The currently
  running command is `python3 Tools/InstrumentsPrototype/compatibility_harness.py
  --matrix template-additions --cross-template-order --max-cases 500 --run`.
  If interrupted, rerun that command to resume remaining cases. The harness
  removes each temporary trace after export.
  At its halfway checkpoint, 250 new cases had been appended (831 distinct
  cases overall). The Data Faults, Data Fetches, Data Saves, Disk I/O,
  Disk Usage, Display, Filesystem Activity, and Filesystem Suggestions
  groups had produced no new hard error pattern beyond the already known
  Processor Trace timeout; known duplicates and platform/privacy skips were
  classified without recording.
  At case 419 of the batch, the survey crossed 1,000 distinct completed
  finite cases. The later GPU, HTTP Traffic, Hangs, and initial Hitches cases
  had likewise yielded no new hard-error pattern; HTTP Traffic was
  privacy-skipped by default.
  Shortly afterward, CPU Profiler plus an added Hitches instrument reported
  “Data source agent failed to setup” with the misleading CPU Counters
  removal suggestion. The reverse composition (Animation Hitches plus CPU
  Profiler) had already failed twice. This new direction needs a targeted
  confirmation before becoming a generated hard-pair rule.

- Completed that 500-case batch: 1,081 distinct cases are now classified in
  the 5,398-case finite plan. The 860 template-addition results include 488
  valid, 49 valid with warnings, 52 duplicate instruments, 113 derived
  platform failures, 101 privacy skips, 28 hard recording errors, 28
  timeouts, and one unsupported attached target. CPU Profiler plus Hitches
  failed again on a targeted rerun with the same data-source setup error.
  The generated filter now has six repeatable hard-pair exclusions and two
  Windowed Mode pairs with a typed Capture Last override. The Swift library
  built with this refreshed filter. The harness work directory is empty and
  no new TCC denial appeared. The Mac Catalyst Debug app also built after
  adding the PID to trace history; its only build warning was the existing
  missing Metal toolchain search path.

- Added an environment manifest for the results file (macOS 27.0, Xcode
  27.0/27A266a, arm64). Future harness runs compare it with the selected
  Xcode and also check all four source catalog build tags. A file lock now
  prevents parallel writers, and a resumed run repairs only an interrupted
  partial final JSON line. Added optional automatic confirmation of new hard
  errors except the established missing CPU counting mode.

- Started the remaining 715 template-addition cases with
  `--cross-template-order --confirm-errors`. This finishes the 25-by-63
  one-added-instrument matrix if it runs to completion. Added the repository's
  MIT license to the self-contained source package so its archive carries
  the notice required for sharing the prototype.
  Early in that run, CPU Profiler plus Metal Performance Overview failed
  twice with the same data-source setup error and misleading CPU Counters
  removal suggestion seen in other hard pairs. The `--confirm-errors` run
  recorded both outcomes. This becomes a generated exact-pair exclusion when
  the filter is next refreshed; it is not a macOS platform or TCC denial.
  Later, two Processor Trace additions produced repeatable hard errors in
  separate parent templates: Audio System Trace reported “Import source file
  doesn't contain valid processor trace data” twice, while CPU Profiler
  reported the same data-source setup/CPU Counters suggestion twice. The
  short Audio recording may lack processor data and is not yet treated as an
  intrinsic pair exclusion; the CPU Profiler resource conflict qualifies for
  the generated hard-pair map. Other Processor Trace additions have timed out.
  By case 423 of 715, the durable result file had passed 1,500 distinct
  finite cases. CPU Profiler plus SwiftUI also failed twice in this direction,
  matching the earlier failure of SwiftUI plus an added CPU Profiler. The
  per-case temporary trace directories continued to be removed.
  At Game Performance plus VM Tracker, `xctrace` itself aborted with
  `std::runtime_error: Page pool's backing file has been removed from the
  file system`; export then failed with `Document Missing Template Error`.
  The harness classified this as `unverified`, kept the diagnostic text, and
  removed the disposable bundle. It needs a targeted rerun before treating
  it as an invariant. This was not a TCC denial.

- During that background sweep, tightened the app's loopback request and
  stop writes to handle a partial socket send. Sandboxed Mac Catalyst build
  attempts hit an inaccessible default DerivedData directory and a malformed
  Observation macro-plugin response. A build using the project file outside
  the sandbox also lacked the workspace's MarkdownUI dependency. Retrying
  with the Tuist workspace exposed a small `Data` versus `[UInt8]` type error
  in the new write helper; fixed it. The final unsandboxed Mac Catalyst Debug
  workspace build with `LOCAL_INSTRUMENTS_TRACING` and signing disabled
  succeeded. These build-environment issues were unrelated to Instruments or
  TCC.

- Preserved old app trace-history entries when adding PID display: PID is now
  optional in the persisted record, and the UI shows it only for new entries
  that contain one. A second Mac Catalyst Debug workspace build passed.

- **Disk incident and guard:** The user interrupted the addition sweep after
  finding roughly 350 GB of accumulated Instruments ktrace scratch files in
  `/private/var/folders`; the machine was running low on disk. The running
  sweep was stopped at 553 of the 715 pending additions. A process check found
  no remaining harness, `xctrace record`, or CPU fixture process. Fifteen
  fresh `instruments*.ktrace` files remained in the active temporary
  directory, totaling 3.31 GiB; removed those exact files. Free space was
  49 GiB afterward. This scratch growth was a real defect in the original
  harness cleanup: its per-case `.trace` bundle was removed, but Xcode's
  separate ktrace files in the user's temporary directory were not.

- Updated the harness to direct each child to a per-case `TMPDIR`, monitor
  both that directory and newly created global `instruments*.ktrace` files
  every 250 ms, terminate a case above a 256 MiB default scratch cap, and
  stop before a case if free disk is below a 40 GiB floor. It now removes
  global ktrace files created during each case even when `xctrace` ignores
  `TMPDIR`, and cleans a child recorder on interruption. A one-case Activity
  Monitor run completed with a valid export and removed its 3.48 MB global
  scratch file. A deliberate 1 MiB cap stopped the next test at 3.1 MiB,
  recorded `scratch-limit`, removed its file, and left no ktrace in the
  watched directory. A sandboxed run also failed to initialize Instruments
  because access to `~/Library/Caches/com.apple.dt.InstrumentsCLI/path_manager`
  was denied; an unsandboxed retry succeeded. This was a sandbox access
  error, separate from TCC and the disk incident.

- The guarded sweep's first resumed case was the previously crashed Game
  Performance plus VM Tracker composition. It exceeded the stricter 128 MiB
  case cap, reaching 401.7 MiB between 250 ms checks. The harness stopped
  immediately and removed the one 458.8 MB global ktrace file. No ktrace
  remained afterward. This pair is now treated as unsafe by the generated
  typed validator on this Xcode build. The cap is deliberately conservative;
  overshoot during one polling interval remains possible.
  The default per-case cap was later tightened to 128 MiB, matching the
  guarded continuation commands used after the incident.

- A later Processor Trace addition to View Body (Legacy) exceeded the 128 MiB
  cap, reaching 569.5 MiB before the watchdog stopped it. Its global ktrace
  file was removed; none remained afterward. The monitor now samples every
  50 ms. Untested Processor Trace combinations and the known Game Performance
  plus VM Tracker hazard are classified `resource-derived` by default, with
  `--include-resource-unsafe` available for an explicit later audit. These
  are not counted as experimentally proven platform incompatibilities.
  Animation Hitches plus View Properties (Legacy) later crossed the cap at
  189.2 MiB and was likewise stopped and cleaned. Added an explicit
  `--continue-after-scratch-limit` mode for the remainder of the finite
  sweep; it preserves the per-case cap, cleanup, and free-space floor.

- Completed all 1,575 standard-template plus one-instrument cases. The final
  addition outcomes were 823 valid, 111 valid with warnings, 125 duplicate,
  228 derived platform exclusions, 154 privacy skips, 35 recording errors,
  61 timeouts, 20 attached-target rejections, six resource-derived skips,
  and twelve scratch-limit stops. The full 5,398-case finite matrix now has
  1,796 classified cases; 3,602 remain, mostly standalone instrument pairs
  and multi-Boolean option combinations. The generated filter has two
  unsupported templates, five unsupported instrument IDs, four exact
  Windowed Mode pair exclusions, nine repeatable hard pair exclusions, and
  twelve exact scratch-cap exclusions. The Swift library rebuilt with this
  filter. No ktrace files or case directories remained after the batch;
  free disk was about 199 GiB. No TCC denial appeared. Several first-run
  recording errors succeeded on immediate confirmation and were not promoted
  to hard-pair exclusions.

- Started a bounded 200-case survey of the 1,953 standalone two-instrument
  combinations in Blank, with the same 128 MiB per-case scratch cap, automatic
  cleanup, 40 GiB free-space floor, privacy skips, and resource-derived
  Processor Trace skips. The first Activity Monitor plus CPU Counters pair
  reported the familiar missing counting mode; neighboring Activity Monitor
  pairs saved valid exports. Results are appended after each case.

- Finished that 200-case instrument-pair batch, bringing the matrix to 1,996
  of 5,398 classified cases. Outcomes were 167 valid, three valid with
  warnings, 17 derived platform skips, seven privacy skips, three
  resource-derived Processor Trace skips, three attached-target rejections,
  and five hard recording errors. Four errors were the familiar CPU Counters
  missing-mode prerequisite. Advanced Graphics Statistics plus Metal
  Performance Overview failed twice with “Failed to stop recording session:
  Data Providers emitted errors: Logging.” Added generation of exact
  two-instrument exclusions from repeatable hard failures (excluding the CPU
  counting prerequisite) and scratch-limit results. The Swift plan validates
  this set among explicitly added instrument pairs; the library built after
  regeneration. There were no leftover ktrace files or case directories;
  free disk was about 198 GiB. No TCC denial appeared.

- Added typed Boolean settings for six Allocations switches, Core AI
  numeric-suffix consolidation, two Metal Performance Overview metrics
  switches, SwiftUI layout tracing, and all-process capture for `os_log` and
  `os_signpost`. They use the native instrument control state's encoded-
  options setter. The Swift library builds and exploratory environment
  selectors exist; their saved-run effect still needs a disposable
  private-recorder check before claiming these recipes work end to end.

- Ran guarded private-recorder checks for those Boolean settings. SwiftUI
  layout tracing saved `{"enableLayoutTracing":true}` in `form.template`
  and exported; its CPU-only fixture naturally produced a no-SwiftUI-data
  warning. Allocations zombie detection, Metal shader metrics, `os_log`
  all-process capture, and `os_signpost` all-process capture each saved the
  expected encoded JSON and exported. The first SwiftUI export test
  accidentally inherited `DYLD_INSERT_LIBRARIES` and crashed its export
  child; clearing that environment before export fixed the test. Each
  disposable trace and global ktrace scratch file was removed.

- Core AI was the exception. Its suffix-consolidation setting saved
  `false` and exported, but two private-recorder runs each reported 40
  missing-GPU-device counter/shader issues and returned `runIssues`, while
  a default private Core AI run saved with zero issues. The CLI option
  variant had also recorded validly. This points to the current native
  setter path rather than an intrinsic option restriction. Removed the
  Core AI switch from the public typed facade until a working private
  mapping is found. No TCC denial occurred.

- Completed another 300 standalone instrument pairs. The full finite matrix
  is now 2,296 of 5,398 cases; 505 of 1,953 pair cases are classified. The
  generated pair map contains five repeatable hard conflicts: CPU Profiler
  with Hitches, SwiftUI, or Metal Performance Overview; Metal Performance
  Overview with Advanced Graphics Statistics or Audio Statistics. CPU
  Counters plus other instruments in Blank consistently lacked a counting
  mode and were excluded from the intrinsic-pair map. The Swift library
  rebuilt with the refreshed catalog. A linked consumer verified that an
  Activity Monitor plan explicitly adding CPU Profiler and Hitches is
  rejected before recording. The temporary consumer was removed. No ktrace
  or harness case directory remained after the 300-case batch; free disk was
  about 196 GiB. No TCC denial appeared.

- Started a guarded 200-case run of the remaining full Boolean option
  combinations, beginning with Allocations. The finite options family has
  1,782 cases; 128 single-field variants were already classified. The
  running batch uses the same scratch cap, cleanup, and free-space floor.
  Its early Allocations combinations have saved valid traces; exact changed
  fields are recorded in each JSONL row.

- Completed the entire Allocations option family: all 255 Boolean
  combinations and its one numeric sample saved and exported valid traces.
  The first 200-combination batch and the remaining 47 both left no ktrace
  files behind. Free disk was about 195 GiB. This is complete for the finite
  Boolean state space of the selected Allocations template, though it does
  not establish the semantic effect of every switch on this CPU-only target.

- Started the CPU Counters full Boolean matrix (513 option cases including
  two numeric samples; eleven single-field cases were already classified).
  Early multi-field runs saved valid traces or exportable time-sample period
  warnings. Added its four Boolean recording controls to the typed
  `CPUCounterSettings` archive patcher, preserving unspecified fields from
  the installed template. The library builds; an end-to-end private-recorder
  check is pending completion of the concurrent CLI sweep.

- The first 250 new CPU Counters Boolean combinations completed with valid
  exports or nonfatal sampling-period warnings; no hard option rejection.
  A guarded private-recorder CPU Counters run using all four newly wrapped
  Boolean switches saved `sampleByTime=false`,
  `useDebuggingInformation=true`, and both high-frequency mode flags `true`
  in `form.template`. It returned zero run issues, exported a table of
  contents, and removed its 23 MB global ktrace scratch file and disposable
  trace. This verifies that typed setter path for this combined selection.

- Finished the CPU Counters option family: all 511 Boolean combinations
  exported (213 valid, 298 valid with nonfatal sampling-period warnings),
  and both numeric samples were valid. No hard combination failure was
  found. The overall finite matrix is now 3,045 of 5,398 classified cases,
  with 2,353 remaining. No global ktrace files or harness case directories
  remained after the CPU batch; free disk was about 184 GiB. No TCC denial
  appeared.

- Made `DebugTraceTemplate` and `DebugInstrumentsTrace.run` public under the
  existing opt-in Mac Catalyst Debug compilation guard, so another app event
  can be wrapped at its call site. The first build found a Swift 6 detached-
  task isolation error because the newly public profile enum was not
  `Sendable`; adding that conformance made the full Mac Catalyst Debug
  workspace build pass. The current UI still wraps tape generation, while
  other app events can use the documented closure API when explicitly wired.

- Expanded the opt-in SwiftUI trace control with an **All traces** sheet so
  the full retained 200-entry history remains browsable instead of only its
  three recent links. Each sheet row shows algorithm, profile, time, PID
  when present, and repetition count, with a link to the saved trace. The
  Mac Catalyst Debug workspace build passed. This change does not run or
  retain any additional trace data.

- Rebuilt the Mac Catalyst Debug app without `LOCAL_INSTRUMENTS_TRACING` in
  a separate DerivedData directory; it passed. This confirms the recent
  public debug API and full-history sheet do not require trace code in an
  ordinary build, alongside the earlier guarded source inspection.
  Removed the separate 1.8 GB plain-build DerivedData after verification;
  the opt-in Debug build remains available for the local demo.

- A separately linked Swift consumer checked the regenerated disk-hazard
  rule: Game Performance plus `.vmTracker` failed `TracePlan.validate()`
  before any recorder started, with a message about known failure or
  excessive scratch use. The temporary consumer source and binary were
  removed; no trace was created.

- Revisited the two earlier stop hangs with hard timeouts. Both Allocations
  and Processor Trace completed as 100 ms `xctrace` CLI runs and exported.
  A 100 ms private Allocations run also stopped and exported. The private
  Processor Trace run remained `isRunning=1` after 15 seconds, despite
  `saveDocument:` returning success; `xctrace export` rejected that bundle
  with a fatal run error. Fixed the wrapper to return typed `stopTimedOut`
  instead of success in this state, and made Processor Trace fail local-Mac
  plan validation until its stop lifecycle is understood. Removed all four
  test bundles, diagnostic logs, and the fixture afterward. A linked Swift
  consumer check confirmed that `.processorTrace` now throws the intended
  validation error before recording.

- Verified the new app request field through the actual token-protected
  loopback host on port 27729. A disposable process received `READY` and
  `DONE`; its saved Time Profiler trace exported
  `high-frequency-sampling=1`. Stopped the host and removed the trace and
  target. The first client attempt hit this task's sandbox denial for
  localhost sockets; the narrowly escalated request succeeded. No TCC
  denial occurred. The recurring `_LSModifyNotification` assertion text
  appeared but created no run issue.

- Resolved the native-option gap left by template archive patching. The
  loaded Points of Interest and Hangs `XRInstrument.recordingControlState`
  accept UTF-8 JSON via `setValue:forKey:@"optionsEncoded"`. Separate bounded
  traces exported `excludeOSLogs=true` and priority inversion detection=1.
  The Swift `TraceSetting` API now sends typed native option specifications
  to the Objective-C bridge after template load. A combined bounded Time
  Profiler trace exported POI exclusion=true, inversion detection=1,
  Hangs threshold=33 ms, and all four Time Profiler switches=1. The bridge
  rejects an absent requested instrument instead of silently ignoring it.
  The failed pre-load archive insertion remains documented as a negative
  experiment. These diagnostic traces and target were removed.

- Wired a High Frequency toggle into Sort Symphony's opt-in Mac Catalyst
  Debug trace control for CPU Profiler, Time Profiler, and CPU + File
  Activity. Its loopback request carries the flag; the host builds the
  matching typed `TraceSetting` and rejects it for unsupported templates.
  Trace history records the choice with an optional field so older persisted
  entries decode. The generated Tuist workspace's `SortFeature` Mac Catalyst
  Debug scheme built successfully with `LOCAL_INSTRUMENTS_TRACING` enabled.
  An initial sandboxed app build failed because Xcode's Swift macro server
  was blocked. A project-only build then could not resolve `MarkdownUI`
  because it excludes workspace package projects. The escalated workspace
  build succeeded; these were build-environment issues, not source errors.

- Built a declarative Swift settings surface (`TraceSetting` in
  `TraceSettings.swift`) and integrated it with `TracePlan.build`, including
  optional branches and loops. Validation checks template setting groups,
  duplicate groups, unsupported Immediate mode, positive CPU counter
  parameters, finite positive Processor Trace buffers, and bounded snapshot
  intervals. `TemplateArchivePatch` copies the selected Xcode archive,
  applies validated changes, and the recorder deletes the copy afterward.
  No installed Xcode template is edited.
  `TraceTemplate` originally had cases for all 25 standard templates; its
  macOS facade now omits the two platform-only cases. The local-Mac
  plan validator rejects the two verified platform conflicts: Power
  Profiler needs iOS/iPadOS, and RealityKit Frames/Metrics need visionOS.
- End-to-end private-recorder verification: saved Time Profiler traces
  reported `record-waiting-threads=1` and, separately,
  `high-frequency-sampling=1`. High frequency required setting both
  `highFrequency` and `highFreqSampling` in the archived command state;
  either alone exported as false. A CPU Counters trace saved
  `pmiThreshold=2000000` in its `optionsEncoded` blob. A 2.5-second Leaks
  trace saved a one-second (`1000000` microsecond) snapshot interval with no
  run issues. The test traces and two retained diagnostic template copies
  were removed. `build.sh`, a consumer result-builder typecheck with an
  optional settings branch, and `git diff --check` passed.
  A linked consumer validation run also rejected Immediate File Activity,
  CPU Profiler settings on Time Profiler, and local-Mac Power Profiler;
  it accepted a valid Time Profiler plan. That run did not start a trace.
- Ran a bounded Blank + Core Animation Commits trace with
  `expensiveCommitSampling=1`. Its saved archive contained that integer in
  the instrument's `optionsEncoded` JSON, while the generic command switch
  `sampleExpensiveCACommits` remained 0. Decoder probes already showed
  0, 1, and 2 accepted, -1 and 1.5 rejected. Removed the trace and fixture.
  Also found a context-sensitive Processor Trace buffer default: standalone
  added instrument 4, standard Processor Trace template 1.
- The async `recordAsync` path with a declarative waiting-threads setting
  saved an exportable 500 ms Time Profiler trace with
  `record-waiting-threads=1`. Declarative Immediate mode on CPU Profiler
  saved and exported as `Immediate`. Both traces and their disposable
  targets were deleted. The wrapper removed its temporary templates itself.
- Final combined setting checks: Time Profiler exported high frequency,
  waiting threads, kernel callstacks, and context-switch sampling all as 1;
  Hangs threshold exported as 33 ms. CPU Profiler exported high frequency
  and kernel callstacks as 1 with a 33 ms Hangs threshold. POI
  `excludeOSLogs` and Hangs `detectPriorityInversions` did not apply when
  their archive switches were patched. A bounded CLI control run proved the
  same options can work and put their values in native `optionsEncoded`
  blobs. Adding those blobs to the template before load reset unrelated
  Time Profiler settings, so that path was removed. A later live instrument
  setter test resolved both options, as recorded at the top of this section.
- Snapshot checks through the private wrapper: a bounded Game Memory run
  saved `XRVMInstrumentKey_snapRateMicros=1000000` and
  `XRVMInstrumentKey_autoSnapshot=true`; a bounded Leaks manual run saved
  `XRLeakConfigurationAutoLeaksKey=false`. Both reported no run issues.
  Their traces and disposable target were removed. The runs verify saved
  configuration, not effective snapshot cadence.

- Located the missing private numeric storage: CPU Counters and Processor
  Trace each archive an `optionsEncoded` UTF-8 JSON blob inside their
  instrument recording control state. The CPU Counters stock blob has
  `pmiThreshold=1000000` and `processBucketSize=10`; a 500 ms CLI trace
  recorded with `pmiThreshold=2000000` saved that exact number in its
  `form.template` blob. Processor Trace's stock blob includes
  `bufferSizeFill=1`, `bufferSizeWrap=1`, and `throttleEnabled=true`.
  Both CPU test traces, option file, and disposable target were removed.
  This turn's first direct `xctrace` attempt hit a sandbox denial writing
  `~/Library/Caches/com.apple.dt.InstrumentsCLI/path_manager`, before
  template load. Narrow escalated `xctrace` execution resolved it. One
  attempted launch was rejected by automatic approval review because its
  `--time-limit` appeared after `--`; the corrected bounded command ran.

- `FilterValidation.json` now records no-trace decoder checks for the
  Allocations `recordedTypes` model. Only `record`/`ignore` actions and
  `contains`/`hasPrefix` matchers decoded among tested values. Empty and
  duplicate rule lists decoded, as did an empty type string; the typed API
  should reject these ambiguous/empty configurations itself. A temporary
  Leaks template patched to a two-second snapshot interval saved an
  exportable 500 ms trace, but the run ended before a snapshot, so the
  effective cadence is not yet proven. Its trace and template copy were
  removed. The CPU Counters UI showed Guided/Manual modes, a hardware-
  dependent guided mode menu, and manual event sampling at one million
  `CORE_ACTIVE_CYCLE` events by default.

- Mapped private Hangs threshold values with seven temporary template-copy
  traces: `0=500 ms`, `1=250 ms`, `2=100 ms`, `3=33 ms`; `-1`, `4`, and `99`
  all exported as 100 ms. All seven traces were removed. In the CLI options
  JSON, by contrast, `hangsThreshold` is an integer millisecond count and
  accepted 0 and 251 ms in saved traces. The eventual typed API must
  translate only the four verified presets to private values or use a
  separate exact-millisecond route; it must not pass CLI milliseconds as
  private enum codes.
- Inspected in-memory `XRInstrument.traceTemplateData` and its archived
  representation. Leaks stores a ten-second snapshot interval as
  `XRLeakConfigurationCheckIntervalKey=10000000`; VM Tracker stores three
  seconds as `XRVMInstrumentKey_snapRateMicros=3000000`. These are
  microseconds and live in per-instrument data, not the command control
  state. CPU Counters and Processor Trace template data did not expose their
  numeric option fields as plain keys in this inspection. Test traces and
  copied template files from the private setter and archive probes were
  removed after their outcomes were recorded.

- Added `PROFILE_INVARIANTS.md` as the human-readable compatibility record,
  backed by JSON catalogs for every standard template and all 63 registered
  instruments. It separates archive/UI/decoder/recorded evidence and lists
  known invalid combinations. A 500 ms baseline sweep produced 19 exportable
  traces. Power Profiler reported macOS unsupported (iOS/iPadOS required),
  and RealityKit Frames/Metrics reported visionOS required. Allocations and
  Processor Trace were skipped due prior stop hangs. Foundation Models and
  Network initially appeared to time out; bounded diagnostic reruns showed
  both were waiting at interactive privacy warnings, not TCC errors. The
  warning says Foundation Models stores prompts/responses unencrypted in the
  trace and logs; Network can capture all HTTP traffic on the Mac during and
  for up to 60 seconds after recording. These prompts were not bypassed.
  Every baseline and diagnostic temporary trace and fixture process was
  removed afterward.

- Comprehensive option survey: `xctrace list templates` reports 25 standard
  templates, and `list instruments` reports 63 standard instruments. Queried
  `record --show-recording-options` for every template and saved the full
  results in `OptionsCatalog.json`. Parsed installed binary
  `.tracetemplate` archives into `TemplateArchiveCatalog.json`; 31 archives
  with command options were found (including duplicate template names in
  different packages). The latter captures Immediate/Deferred/windowed
  support and archived numeric switch defaults.
- Validation caveat: `--show-recording-options` ignores
  `--recording-options <file>` entirely, including malformed files. Actual
  `xctrace record` requires a complete options JSON document; a partial
  document fails with exit 57 and “data ... is missing,” while a wrong type
  fails with exit 57 and “incorrect format.” An unknown key was silently
  tolerated through a valid saved trace. A high-frequency Time Profiler
  option in complete JSON yielded a trace with `Sampling Frequency: High`.
  Some runs returned CLI exit 54 even though `xctrace export` confirmed valid
  saved data, so the exit code alone is not a sound validity test. All traces
  from this CLI validation batch were deleted immediately after export.
- `PFTInstrumentCommand recordingControlState` exposes a KVC-compatible
  `XRInstrumentControlState`; it has `_setKey:value:` and
  `setControllerKey:modeValue:` selectors. Mutating its archived keys via
  KVC on the copied command, the template command, or the instrument state
  read back successfully but **did not change** exported Time Profiler
  options. A temporary copy of the Time Profiler `.tracetemplate` archive,
  patched at the command's `recordWaitingThreads` value before loading,
  **did** produce a valid trace whose `time-profile` table reported
  `record-waiting-threads="1"` with zero run issues. The original Xcode
  template was not modified. Template archive patching is therefore a
  verified option-setting route; the live setter route remains unresolved.

- Began a declarative-options survey in the actual Instruments 27 UI,
  creating new unsaved trace documents without starting recordings. CPU
  Profiler exposes `Record Kernel Callstacks` and `High Frequency Sampling`;
  Time Profiler additionally exposes `Record Waiting Threads` and `Context
  Switch Sampling`. Both templates also include Points of Interest
  (`Exclude os_log messages`) and Hangs (`Enable Priority Inversion
  Detection` and four reporting thresholds, from >500 ms to >33 ms).
  Recorder-level controls include target/device, Immediate or Deferred mode,
  Capture Last, and a stop-after limit. File Activity contains Filesystem
  Suggestions, Filesystem Activity, Disk Usage, and Disk I/O Latency; none
  shows an instrument-specific option, and its Immediate mode is disabled
  with the UI explanation that one or more instruments do not support it.
- The `XRInstrument` Objective-C selectors `currentRecordSettingsDetailMetaUI`
  and `recordingParametersInScope` both returned empty arrays when called on
  freshly loaded CPU/Time templates in the probe. This is a useful negative
  result: selector reflection alone did not expose the visible option model.
  The installed `.tracetemplate` files are binary `NSKeyedArchiver` property
  lists. Their `PFTInstrumentCommand` recording control state includes keys
  such as `highFreqSampling`, `recordWaitingThreads`, `recordKernelStacks`,
  `contextSwitchSampling`, `excludeOSLogs`, `hangsThreshold`, and
  `detectPriorityInversions`. The archives also encode whether Immediate,
  Deferred, and windowed recording modes are supported. The File Activity
  archive marks Immediate unsupported, agreeing with the UI. These keys are
  candidate typed bindings; mutation and round-trip verification remain.
  The probe's optional `INSTRUMENTS_DUMP_OPTIONS=1` output supports further
  inspection. No permission/TCC error arose in this read-only survey.
- A more direct option inventory surfaced in the installed CLI:
  `xcrun xctrace record --template '<name>' --show-recording-options` prints
  JSON without recording. Time Profiler returned
  `contextSwitchSampling`, `highFrequencySampling`, `recordKernelStacks`,
  and `recordWaitingThreads`; CPU Profiler returned `highFrequency` and
  `recordKernelCallstacks`; both returned Hangs `hangsThreshold: 250` and
  `detectPriorityInversions: false`, plus Points of Interest
  `excludeOSLogs: false`. File Activity returned `{}`. Crucially, these
  external JSON keys differ from some internal archive switch names, so the
  JSON is the better catalog for a public typed options model. UI inspection
  still supplies compatibility constraints and descriptions that this JSON
  omits. `--recording-options <file>` may be a useful control for validating
  intended settings, even though the final recorder uses the private APIs.

- Tested the installed `Activity Monitor` template through the signed
  carrier with the CPU fixture. The two-second run saved with zero issues;
  exported tables contained **1 `activity-monitor-process-ledger` row** and
  **2 `activity-monitor-process-live` rows**. Added it to the typed template,
  host allowlist, and app picker. It is a coarse process overview at this
  duration; the app picker compiles but has not been exercised for this
  profile. The same nonfatal `_LSModifyNotification` messages appeared.

- Discovered `PFTInstrumentList addInstrumentWithIdentifier:` on Xcode 27.
  Adding `com.apple.dt.instruments.fs-syscalls` to the CPU Profiler template
  produced a valid custom trace with both CPU and filesystem tables. Promoted
  this to `TraceInstrument.filesystemActivity`, a `TracePlan` addition, and a
  `CPU + File Activity` choice in the app's debug picker. The host accepts
  only known identifiers and rejects duplicates; `TracePlan` rejects adding
  filesystem activity to the File Activity template, which already has it.
  The bridge reports status 11 if Instruments rejects an added instrument.
- Verified the typed host path with an attached file-activity fixture:
  `/private/tmp/SortSymphonyTraces/typed-combined-18455-1789935341959.trace`
  ran for 1.474702 seconds with no run issues and exported **1 `cpu-profile`
  row and 3,738 `FsSyscall` rows**. The fixture spends most of its time in
  `usleep`, explaining the sparse CPU table. The opted-in full Mac Catalyst
  build passed; Xcode printed existing missing Metal toolchain search-path
  warnings. No permission or TCC failure occurred. The app picker compiles,
  but a combined profile has not yet been launched through the actual UI.
  Exported trace metadata included target environment variables, so traces
  should be reviewed before sharing.
  The carrier printed `_LSModifyNotification` `noErr` assertion messages
  during setup; they did not create run issues or prevent saving this trace.

- Added `TracePlan.recording(_:of:for:savingTo:)` as a declarative factory
  with preflight checks for duration, target path/PID, template name, and
  output collision. Added `RecordingSession.recordAsync` with a typed
  `RecordingResult` and `RecordingError`; the blocking Objective-C recorder
  runs on a Dispatch thread, outside Swift's cooperative executor.
- Added typed `Time Profiler` and `File Activity` templates. Both now have
  successful recordings with actual table data. `Allocations` remains
  unverified because its first stop hung.
- The app's loopback client now waits for the host's `DONE` response and
  returns the saved trace URL. `SortSession` keeps a per-screen trace history;
  `SortView` has a Debug Mac Catalyst trace count, recent links, and a
  **Record another trace** button to exercise repeated runs on one process.
- The app hook uses the explicit `LOCAL_INSTRUMENTS_TRACING` compilation flag
  with Debug and Mac Catalyst guards. Local builds must opt in with
  `SWIFT_ACTIVE_COMPILATION_CONDITIONS='DEBUG LOCAL_INSTRUMENTS_TRACING'`;
  ordinary and Xcode Cloud builds omit the code and UI by default. A first
  attempt to infer Cloud inside the Tuist manifest from `CI_XCODE_CLOUD` did
  not emit the expected flag even after cleaning manifest caches, so it was
  removed rather than trusted.
- The declarative `TracePlan.build { ... }` result builder accepts one typed
  template, target, duration, and output. It rejects missing or duplicate
  directives before entering private frameworks. The loopback host now uses
  this builder. `RecordingSession.recordAsync` emits `started` and `completed`
  callbacks and returns a typed result; its runtime behavior and thread
  caveat are recorded below.
- Verified the expanded app UI twice on PID 10213: the trace count advanced
  1 → 2, and both saved CPU traces contained samples (6 and 142 rows). The
  small first count reflects how quickly this sort completed, and motivates
  exact event-end stopping and signposts for microtargeted work.
- A two-second Time Profiler run of the busy fixture saved with zero run
  issues and **1,705 `time-profile` rows**. A two-second File Activity run
  of `file_activity_target.c` saved with zero run issues, 2.07 seconds of
  duration, and **6,530 `FsSyscall` rows**. No new permission/TCC denial.
- The SwiftUI debug control now selects CPU Profiler, Time Profiler, or File
  Activity. From the real app on PID 13322, selecting Time Profiler and
  pressing **Record another trace** added a second history entry; its
  `time-profile` table contained **89 rows**. The ordinary SortFeature Debug
  build (without the local flag) and the opted-in full app build both pass.
- Added an `OSSignposter` interval named `Tape generation` around the exact
  `TapeFactory.makeTape` operation after the host's `READY` signal. This
  compiles under the opt-in SortFeature build, but two exported CPU traces
  showed **no `OSSignpostIntervals` or raw `os-signpost` rows**, even after
  changing the category to `PointsOfInterest`. Do not count exact event
  markers as working yet. Investigate signpost enablement/trace buffering
  before relying on them for microtargeted attribution.
- Added an optional `STOP` line to the loopback protocol. The private
  recorder polls that socket after a 50 ms minimum and ends the trace when
  the app finishes `TapeFactory.makeTape`; duration remains a fallback cap.
  A Python client requested a five-second CPU trace, sent `STOP` after
  0.2 seconds, and received a valid 0.605-second trace with 90 CPU rows.
  The real app requested a ten-second cap, sent `STOP`, and saved a
  0.605-second trace. That first one-run sort had zero CPU rows because the
  actual work was too short for this sampling setup.
- Added a debug **Runs** picker (1, 10, 50, 100). The app repeats the same
  algorithm's tape generation inside one trace and plays back the last tape.
  On PID 15739, a 50-run Binary Insertion Sort capture stopped at 0.595
  seconds and exported **49 CPU profile rows**. The SwiftUI history advanced
  from one to two traces against that same PID. This is the validated way to
  profile very fast sorts until exact signpost intervals are working.
- Added `build.sh`, which discovers the selected Xcode path, builds the
  Objective-C bridge and Swift dynamic library/module into
  `/private/tmp/instruments-prototype-build`, and prints both artifact paths.
  It ran successfully. The prototype remains in `Tools/InstrumentsPrototype`
  rather than a separate Swift package because the private framework and
  signed-carrier bootstrapping still need a local Xcode-specific build.
- Compiled a separate Swift consumer against the emitted module and dylib.
  A valid result-builder recipe succeeded; duplicate templates and zero
  duration both threw `RecordingError.invalidPlan` before invoking private
  APIs. That small check printed `recipe validation passed`. Its first
  compile attempt hit Codex's filesystem sandbox trying to write the default
  Clang module cache; using `-module-cache-path` under `/private/tmp` fixed
  that environment issue. No TCC prompt or denial was involved.
- Moved the app trace list into a shared `@Observable` debug history that
  stores up to 200 entries in `UserDefaults`, including trace URL, algorithm,
  profile, repetitions, PID, and time. Verified that a Binary Insertion Sort
  trace stayed visible after navigating to Binary Merge Sort, which added a
  second trace on PID 16036. After terminating and reopening the debug app,
  both earlier links and the count of two reappeared before the new app
  finished its next trace. The packaged `build.sh` dylib was the host in this
  test. The host and temporary app instances were stopped afterward.
- Added optional shared-token authorization for the loopback host. Setting
  `INSTRUMENTS_TRACE_TOKEN` requires matching `SORT_SYMPHONY_TRACE_TOKEN`
  from the app. A test request with a wrong token received
  `ERROR unauthorized` before template loading or process attach. The
  protected host was stopped afterward. This is opt-in for the current
  prototype; when unset, any local client can request a trace.
- **Async abnormality under investigation:** the first runtime call to
  `recordAsync` from a Dispatch worker aborted inside
  `DVTPlatform.loadAllPlatformsReturningError:` during
  `PFTInitializeSharedFrameworks`. Crash report:
  `~/Library/Logs/DiagnosticReports/xctrace-2026-09-20-144613.ips`.
  This initialization appears to require the main thread. The synchronous
  recorder remains working. Calling `instruments_prepare` on the main actor
  first allowed a subsequent async Time Profiler trace to complete with
  **1,547 profile rows** and zero run issues. The framework printed
  `DVTInstrumentsFoundation THREADING` warnings for package lookups on the
  secondary queue. A follow-up attempt to run the whole recorder on the main
  Dispatch queue instead timed out during preflight (`status 8`): the private
  asynchronous start apparently needs that queue free. The adapter therefore
  uses a serial Dispatch queue after main-thread initialization. Its thread
  warnings are an unresolved experimental limitation, not a proven fatal
  error. A final one-second serial-queue async trace completed with zero run
  issues and **554 Time Profiler rows**. The async sample initially spent
  extra time in `waitpid` after saving because the CPU fixture kept running
  for its 30-second loop; this was not a trace save hang. Spawned-target
  cleanup is now bounded: TERM gets 0.5 seconds, then KILL is used only for
  the process this probe launched. The final async run returned promptly.

- Completed the Leaks finite option family: all 255 Boolean combinations
  and its one numeric sample saved exportable traces, with no hard errors or
  warnings. The full matrix is now 3,292 of 5,398 classified cases, with
  2,106 remaining. The harness removed all test traces and ktrace scratch;
  free disk was about 183 GiB after the batch. The short CPU fixture does
  not establish that an automatic leak snapshot fires at its configured
  interval. No TCC denial appeared.

- Completed the Game Memory finite option family: all 120 remaining Boolean
  combinations saved valid, exportable traces. The matrix is now 3,412 of
  5,398 cases classified, with 1,986 remaining. The guarded batch removed
  all test traces and global ktrace scratch; free disk was about 182 GiB.
  No TCC denial or other permission failure appeared.

- Completed the Game Performance finite option family. Of its 64 cases, 19
  were valid, 38 were valid with nonfatal warnings, and seven hit the 128 MiB
  scratch cap. Every capped case selected the 100 ms Hangs threshold, but
  other 100 ms combinations passed, so this is recorded as resource-sensitive
  behavior rather than an invalid-combination invariant. The largest observed
  per-case cleanup exceeded 200 MiB because Instruments can grow a file
  between 50 ms polls. No scratch files remained after the batch and no TCC
  denial appeared.

- Completed the Game Performance Overview finite option family. All 57
  previously pending Boolean combinations saved valid, exportable traces;
  no warnings, scratch-limit stops, or permission failures appeared.

- Completed the Swift Concurrency finite option family. All 57 previously
  pending Boolean combinations saved valid, exportable traces with no
  warnings, scratch-limit stops, or permission failures.

- Completed the SwiftUI finite option family. All 57 pending Boolean
  combinations saved exportable traces and reported the same nonfatal warning
  that the synthetic CPU fixture produced no SwiftUI activity. No recording,
  scratch, or permission failure occurred.

- Completed all 64 System Trace option cases: 24 valid and 40 valid with a
  nonfatal Time Profiler sampling-period mismatch warning. All traces were
  exportable; no scratch-limit, recording, or permission failure occurred.

- Completed all 64 Time Profiler option cases. Every one of the 57 exhaustive
  additions saved a valid, exportable trace without warnings, scratch-limit
  stops, or permission failures.

- Found the cause of the apparent post-cleanup disk leak. The long-lived
  Instruments `DTServiceHub` retained 3,911 deleted ktrace files through open
  file descriptors, totaling 367.34 GiB. A normal TERM released them at once,
  raising free space from about 152 GiB to 518 GiB; Instruments relaunched the
  service automatically. The harness now checks deleted-open ktrace storage
  after every case, stops at 512 MiB by default, and can TERM only the retaining
  service with `--reclaim-deleted-scratch`. A controlled scratch-heavy test
  detected 456 MiB retained, restarted the service, and held free space steady.

- Completed all 32 Animation Hitches option cases: four valid, two valid with
  warnings, and 26 scratch-limit stops. The guarded continuation restarted
  `DTServiceHub` 15 times when it retained deleted scratch. No visible ktrace
  files remained; free space was about 515 GiB. These results are classified
  as resource limits, not invalid profile combinations.

- Completed all 31 Core AI option cases. The 26 exhaustive additions all
  saved valid, exportable traces. This CLI patched-template result differs
  from the earlier private native setter experiment that returned missing GPU
  counter issues, so the unsafe Core AI setter remains excluded from the typed
  public API. No disk or permission anomaly appeared in this batch.

- Completed all 32 Metal System Trace option cases. Every one of the 26
  exhaustive additions saved a valid, exportable trace without warnings,
  scratch-limit stops, or permission failures.

- Finished the entire finite option matrix. App Launch's final 11 cases were
  five valid and six valid with warnings; all 11 CPU Profiler cases and the
  last Logging case were valid. Audio System Trace's final case hit the
  scratch cap. Power Profiler and RealityKit Trace options were classified
  from their proven macOS template exclusions, and Processor Trace options
  from its proven resource exclusion. Overall coverage is now 3,950 of 5,398;
  the only remaining cases are 1,448 two-instrument pairs. Cleanup left zero
  visible ktrace files and about 515 GiB free. No TCC denial appeared.

- Completed another 300 two-instrument pairs. The batch introduced no new
  hard incompatibility: 202 were valid, five valid with warnings, 73 derived
  platform exclusions, ten privacy skips, five resource-derived skips, and
  five attached-target rejections. Coverage is now 4,250 of 5,398, with 1,148
  pairs remaining. No visible ktrace files remained and free space held at
  about 515 GiB.

- Completed the next 300 pairs: 234 valid, four valid with warnings, ten
  scratch-limit stops, 25 derived platform exclusions, 14 privacy skips, six
  resource-derived skips, and seven attached-target rejections. The new exact
  scratch-sensitive pairs include Core Data activity with System Call Trace
  or Thread Activity, storage instruments with SwiftUI, and Disk I/O Latency
  with Metal Application. The service-reclamation guard kept free space at
  about 515 GiB. Coverage is 4,550 of 5,398, with 848 pairs remaining.

- Completed another 300 pairs: 147 valid, four valid with warnings, three
  scratch-limit stops, 64 derived platform exclusions, 69 privacy skips,
  eight resource-derived skips, and five attached-target rejections. New
  capped pairs included Filesystem Suggestions with SwiftUI and GPU with
  System Call Trace or Thread Activity. Coverage is 4,850 of 5,398, with 548
  pairs remaining; free space stayed near 515 GiB with no visible ktrace files.

- Completed the final 548 pair cases and therefore the entire 5,398-case
  finite matrix. Final status counts are 3,390 valid, 612 valid with warnings,
  125 duplicates, 623 derived platform exclusions, seven direct platform
  exclusions, 269 privacy skips, one privacy prompt, 94 recording errors, 74
  resource-derived skips, 61 scratch-limit stops, 75 target rejections, and
  67 timeouts. The regenerated compatibility filter contains 20 exact pair
  rules: five repeatable recording failures and 15 scratch-limit protections.
  Cleanup left zero visible ktrace files and about 515 GiB free. No TCC denial
  appeared during the completed guarded matrix.

- Final verification passed: Python compilation, shell syntax, `git diff
  --check`, the standalone Swift library build, the opt-in Mac Catalyst Debug
  build, and the ordinary Mac Catalyst Debug build without the local tracing
  flag. The source package was created at
  `/private/tmp/InstrumentsPrototype-Xcode27.tar.gz`, extracted independently,
  and rebuilt successfully. Its archive contains no trace bundles, lock files,
  or Python bytecode caches. The ordinary app build emitted existing project
  and missing Metal toolchain search-path warnings but exited successfully.

- Expanded the Sort Symphony profile picker and loopback allowlist from 12
  to 20 choices. It now includes every standard template with a validated
  macOS attached-process baseline except App Launch (launch semantics), the
  privacy-sensitive Foundation Models and Network templates, the two proven
  platform exclusions, and resource-unsafe Processor Trace. The 20th choice
  is CPU + File Activity. The standalone library and opt-in Mac Catalyst build
  pass, and a source-to-host mapping audit found no missing picker mapping.

- Added typed ordered Allocations filters with closed `record`/`ignore`
  actions and `contains`/`hasPrefix` match modes, matching the decoder survey.
  Validation bounds the type string and rejects the bridge protocol's
  semicolon delimiter. A 0.2-second private Allocations run persisted both a
  `record contains Sort` rule and an `ignore hasPrefix NS` rule in
  `form.template`; its trace TOC exported successfully.
  The first fixture choice (`/usr/bin/yes`) flooded captured stdout, but the
  recorder completed and left no process behind. The disposable 11 MiB trace
  and its 3.7 MiB ktrace scratch file were removed.

- Hardened launched-target handling after that noisy fixture: the private
  bridge now opens the spawned target's stdin, stdout, and stderr on
  `/dev/null`. Repeating the same `/usr/bin/yes` Allocations test produced
  only recorder diagnostics, saved cleanly with zero run issues, and left no
  process behind. Its disposable trace and 3.5 MiB ktrace scratch were removed.

- Added a typed `osSignpost` setting with an ordered list of dynamically
  enabled subsystems. The initial app and fixture attempts emitted no rows
  because their `OSSignposter` instances were constructed before recording
  preflight; unified logging cached the subsystem as disabled. Constructing
  the fixture signposter after preflight made a single-process private Logging
  trace export 6 raw signpost rows and 1 completed interval.

- Added **CPU + Signposts** as the 21st app profile. The host adds the
  `os_signpost` instrument to CPU Profiler and enables
  `com.nhubbard.SortSymphony` before replying `READY`; the app's static
  signposter is lazily initialized afterward. The exact combined recipe was
  verified with a delayed CPU fixture: one trace exported 4 raw signpost rows,
  1 completed interval, and 4,354 CPU samples. A first short fixture finished
  during CPU Profiler preflight and exported zero rows. Both fixture runs
  saved but returned the wrapper's synthetic `runIssues` error because the
  launched process exited before the requested duration. Instruments itself
  reported no run issues. Xcode also logged two LaunchServices
  `_LSModifyNotification` assertion messages; they did not prevent saving or
  exporting the trace and were not TCC denials.

- Final verification after the signpost work passed the standalone library
  build, Python and shell syntax checks, `git diff --check`, the opted-in Mac
  Catalyst app build, and the ordinary Mac Catalyst app build. A mapping audit
  found all 19 standard picker templates in the host allowlist and both
  combined recipes in their explicit composition paths. The source archive
  was regenerated at `/private/tmp/InstrumentsPrototype-Xcode27.tar.gz`,
  extracted independently, and rebuilt successfully. Final cleanup found
  `DTServiceHub` retaining five deleted ktrace files totaling about 17 MiB;
  terminating that exact service instance released them. Cleanup ended with
  zero visible or deleted-open ktrace files and about 515 GiB free.

- Audited documentation after the functional prototype was complete. Before
  this pass, only 14 of 105 declarations beginning with `public` had adjacent
  DocC comments. All 105 now do. The additions explain optional-setting
  semantics, validation timing, targets, results, typed failures, callback
  queues, cancellation cleanup, signpost enablement order, and the app bridge.
  Internal comments now describe the loopback protocol and seven phases of the
  Objective-C recorder, including the signed-carrier authorization boundary.
  A README documentation map points readers to the API, invariants, chronology,
  and demo material. The standalone library rebuilt successfully afterward.

**Current state:** The typed Swift wrapper runs inside Apple's signed
`xctrace` as a local injected library. The reusable module exposes all
validated macOS templates, selected verified settings, typed Allocations
filters, validated additions, and generated compatibility rules. The
loopback host lets the Mac Catalyst Debug app choose 21 profiles and record
repeated short traces against one PID, with an operation-end `STOP` signal,
repetition picker, and persistent history. All 5,398 finite audit cases are
classified. A standalone ad hoc signed host still fails to acquire kernel
trace resources from `tailspind`. Typed subsystem enablement and combined CPU
plus signpost capture are verified. The async adapter records successfully but
emits private-framework thread warnings.
Local app tracing requires `LOCAL_INSTRUMENTS_TRACING` at build time and
`SORT_SYMPHONY_TRACE=1` at launch.

## Objective

Build a strongly typed Swift wrapper over the private frameworks used by
Instruments so a debug host can make short, programmatically triggered traces
of Sort Symphony algorithms and individual app events. This is a local,
version-specific experiment. The target app should signal a Mac recording host;
it should not link the private frameworks into an iOS or Catalyst target.

## Confirmed environment and authorization

- Xcode is at `/Applications/Xcode.app`; Instruments is under
  `Contents/Applications/Instruments.app`.
- Before the reboot, an ad hoc signed probe with
  `com.apple.private.DTServiceHubClient` and
  `com.apple.private.dt.instrumentsxpc.allowed` was killed before `main`.
  AMFI logged `AppleMobileFileIntegrityError -424` and “The file is adhoc signed
  but contains restricted entitlements.”
- After the user's boot-policy change, `csrutil status` reported disabled and
  `nvram boot-args` returned
  `amfi_get_out_of_my_way=1 ipc_control_port_options=0`.
- The same ad hoc entitlement set now launches. `DTServiceHubClient
  localDeviceConnectionWithError:` returns a live `DTXConnection` and no error.
  This confirms that the earlier AMFI launch barrier and DTServiceHub
  entitlement barrier have been cleared for this probe.
- No TCC denial has been observed in the successful post-reboot launch. An
  earlier `kTCCServiceListenEvent` preflight was attributed by `tccd` to Codex;
  it was not shown to be the recording blocker. TCC behavior while AMFI is
  disabled remains unverified.
- Authenticated root / SSV was not changed for this test. The probe lives in
  `/private/tmp`; it does not alter the sealed system volume.

## Probe and control recordings

- `probe.m` is the Objective-C exploration program. Build it with the command
  in `README.md`, then ad hoc sign it with `Experimental.entitlements`. The
  currently compiled binary is `/private/tmp/instruments-probe`; a fresh build
  overwrites its signature, so sign **after each build**.
- The private path initializes `InstrumentsPlugIn`, finds a template with
  `XRTrace templateItemMatchingName:`, creates a `.trace` directory, calls
  `XRTrace loadTemplate:outputURL:preserveRunHistory:error:`, builds a
  `PFTInstrumentCommand` targeted at a spawned `/bin/sleep`, and calls
  `XRTrace startCommand:`. The output directory must exist before template
  loading because `setOutputURL:` uses a file-reference URL.
- `startCommand:` returning true only queues asynchronous preflight. Confirm
  `isRunning` and the run issues before declaring success.
- An unsigned probe previously failed with “Error connecting to DTServiceHub.”
  A saved package had no run data and `xctrace export --toc` called it malformed.
- Post-reboot, the probe connects to DTServiceHub, but preflight refuses to
  start. With both `Time Profiler` and `CPU Profiler`, it reports each template
  instrument as “deprecated and can no longer be used to record.” This is a
  private-framework setup/type-registration problem, not evidence of a TCC or
  AMFI failure.
- The template instrument objects are `XRInstrument`; their `type` objects
  are `XRStubInstrumentType` with `deprecated == 1`. For `CPU Profiler`, the
  stubs are CPU Profiler, Points of Interest, Thermal State, and Hangs.
- The shared `PFTInstrumentRegistry` contains 15 legacy/native types, but none
  of those four. `XRPackageManager` has 28 loaded packages. Explicitly calling
  `addTypesFromPackage:` for each did not help: modern packages such as CPU
  Profiler have zero entries in their old `instruments` relationship. Loading
  those packages again with `loadPackageAtURL:` produced duplicate Core Data
  store warnings and did not fix registration. That loading loop was removed.
- An Apple-signed control command succeeded on this same boot:
  `xcrun xctrace record --template 'CPU Profiler' --all-processes --time-limit 2s --output /private/tmp/xctrace-cpu-control.trace --no-prompt`.
  `xctrace export --toc` showed a valid run with CPU profiling data.
- The first signed probe run inside Codex's filesystem sandbox threw while
  creating `~/Library/Caches/com.apple.dt.Instruments/path_manager`. The
  Apple-signed `xctrace` hit the analogous CLI cache error inside that sandbox.
  Running either outside the filesystem sandbox fixed this local cache issue.

## Where investigation stopped

**Breakthrough:** the first argument of `PFTInitializeSharedFrameworks` is a
numeric mode bitmask, not an Objective-C object. The earlier `nil`/zero value
excluded Xcode 27's modern native instrument registration. The probe now lets
`INSTRUMENTS_MODE` select the value. Inspection results:

| Mode | Result |
| --- | --- |
| 1, 4 | Template loads, but only 15 old registry types; CPU Profiler etc. are deprecated stubs. |
| 2, 3, 15 | CPU Profiler template was not discoverable. |
| **8, 12** | 65 registry types (63 available); CPU Profiler, Points of Interest, Thermal State, and Hangs are live `NativeInstrumentType` objects with `deprecated == 0`. |

The mode bit `8` enables modern native instruments in this build. The second
argument appears to be an issue responder
object; the probe passes `[NSObject new]`.

**First mode-8 recording result:** `XRTrace.isRunning` became true and
`saveDocument:` returned success. However, `xctrace export --toc` showed a run
duration of only 0.025792 seconds with end reason `Error encountered`; this is
not a usable trace. The run issue said: “Data stream: Recording service missing
'com.apple.private.logging.diagnostic' entitlement.” The entitlement has now
been added to `Experimental.entitlements` for the next test. A successful
`saveDocument:` return is therefore not enough; inspect the run duration, end
reason, and CPU table data. The probe has since been changed to return status
9 if a run issue appears or it stops before its requested two-second duration.
After a valid trace is confirmed, remove
exploratory registry/method logging and build the Swift wrapper.

**Second mode-8 recording result:** with `com.apple.private.logging.diagnostic`
added, the run advanced to a new issue: “Data stream: Recording service missing
'com.apple.private.logging.stream' entitlement.” That key has now also been
added for the next test. This is a sequence of restricted recording-service
permissions; report each one rather than treating the saved package as valid.

**Third mode-8 recording result:** after adding `logging.stream`, the run
reported “Data stream: Recording service missing
'com.apple.private.logging.admin' entitlement.” The issue appeared during
preflight/early recording, sometimes after the immediate `isRunning` check.
That key is now also in the entitlement file. The run still ended in error.

**Fourth mode-8 recording result:** with diagnostic, stream, and admin logging
entitlements present, the remaining issue was “Failed to acquire kernel trace
recording resources (Connection refused). Possibly in use by pid 4129.” PID
4129 is `/usr/libexec/tailspind`. The direct CPU trace ended after about 0.6
seconds with `Error encountered`. A comparable Apple-signed `xctrace` CPU
Profiler recording of one `/bin/sleep` process succeeded with a 2.6-second
run, so the difference is specific to the private recorder/authorization path.
Skipping the probe's explicit `AuthorizationCreate` did not change the error.
Do not classify the kernel trace issue as TCC without evidence.

The probe was also temporarily signed with **every entitlement key present on
Apple's `xctrace`** (PairingManager, CoreSimulator, mobile storage, PlugInKit,
system_installd, in addition to the five already used). It still failed with
the same `tailspind` / connection-refused issue. The extra keys were removed
from `Experimental.entitlements`, and the probe was re-signed with the smaller
set. This narrows the difference to setup, signing trust/platform status, or
kernel tracing behavior beyond the visible entitlement list; it does not prove
which one.

**Working in-process route:** A simple constructor library in
`injection_probe.c` printed its marker when loaded with
`DYLD_INSERT_LIBRARIES` into Apple's signed `xctrace`, confirming that local
injection works under the user's current AMFI policy. `probe.m` now exposes
`instruments_probe_run`; `injected_entry.c` invokes it from a constructor when
`INSTRUMENTS_INJECT_RUN=1`, then exits before the xctrace CLI starts. The
constructor unsets `DYLD_INSERT_LIBRARIES` and `INSTRUMENTS_INJECT_RUN` before
spawning the target, to avoid recursively injecting into the target and
DTServiceHub. The first injected run failed for exactly that recursion reason;
after unsetting the variables, a two-second `/bin/sleep` run saved with no
issues, but it naturally had no CPU samples because the target was idle.

`busy_target.c` was then compiled to `/private/tmp/instruments-busy-target`.
The injected direct-framework recorder saved
`/private/tmp/native-cpu-busy.trace` with no run issues; exporting the
`cpu-profile` table counted **7,371 `<row>` elements** containing backtraces
in the busy target. This proves actual recording rather than just template
loading or a successful save return.

Build the injected library:

```sh
clang -fobjc-arc -DINSTRUMENTS_INJECT_BUILD -dynamiclib \
  -framework Foundation -framework CoreData -framework Security \
  -F /Applications/Xcode.app/Contents/Applications/Instruments.app/Contents/Frameworks \
  -F /Applications/Xcode.app/Contents/SharedFrameworks \
  -framework InstrumentsPlugIn -framework InstrumentsKit \
  -framework InstrumentsTrace -framework InstrumentsPackaging \
  -framework DVTInstrumentsFoundation \
  -Wl,-rpath,/Applications/Xcode.app/Contents/Applications/Instruments.app/Contents/Frameworks \
  -Wl,-rpath,/Applications/Xcode.app/Contents/SharedFrameworks \
  Tools/InstrumentsPrototype/probe.m Tools/InstrumentsPrototype/injected_entry.c \
  -o /private/tmp/instruments-injected-probe.dylib
```

Run it in Apple's signed carrier, with a unique output path each time:

```sh
env DYLD_INSERT_LIBRARIES=/private/tmp/instruments-injected-probe.dylib \
  INSTRUMENTS_INJECT_RUN=1 \
  INSTRUMENTS_TARGET_EXECUTABLE=/private/tmp/instruments-busy-target \
  INSTRUMENTS_OUTPUT=/private/tmp/native-cpu-busy.trace \
  /Applications/Xcode.app/Contents/Developer/usr/bin/xctrace
```

The use of `xctrace` here is only to supply an Apple-signed process identity.
Its recording CLI/parser does not run. The library calls `XRTrace` directly.
This is experimental and depends on the user's altered AMFI policy; the
standalone custom process remains blocked at kernel trace acquisition.

**Typed Swift wrapper:** `probe.m` now exports `instruments_record(pidOrDash,
executablePath, outputPath, templateName, durationSeconds)` as the small
Objective-C-to-C bridge. `RecordingSession.swift` defines `TraceTemplate`,
`TraceTarget`, `TracePlan`, `RecordingError`, and `RecordingSession`. The Swift
entry function is called by `injected_entry.c` after it removes the recursive
injection environment variables. A full Swift run saved
`/private/tmp/native-cpu-swift.trace`; exporting its `cpu-profile` table counted
**7,349 sample rows**. This verifies the typed facade on an actual trace.

**App-trigger prototype:** `instruments_record_with_callback` reports the
moment `XRTrace.isRunning` becomes true. `TraceTriggerServer.swift` listens
only on `127.0.0.1:27727`, accepts a JSON request with PID, executable path,
label, and duration, and sends `READY` from that callback before the target
operation starts. It then sends `DONE <trace path>` after saving. A Python
client attached to a running `busy_target.c` process and received both
messages; the resulting trace exported **7,403 CPU sample rows**. The host
printed two Launch Services `scheduleApplicationNotification` assertion
messages during this attach, but the run had zero issues and valid samples.
No TCC denial was observed.

The persistent host was also tested with **two sequential requests** against
one running process. Both received `READY` and `DONE`, and the resulting
one-second traces contained 2,670 and 3,080 CPU sample rows. The temporary
host was stopped afterward.

`Modules/SortFeature/Sources/DebugInstrumentsTrace.swift` is a Mac Catalyst
Debug-only loopback client. `SortSession.start(size:)` wraps
`TapeFactory.makeTape` in its request/READY handshake when the app's
`SORT_SYMPHONY_TRACE=1` environment variable is set; otherwise the usual
recording path runs. `tuist generate --no-open` completed, and `xcodebuild`
successfully built the `SortFeature` Mac Catalyst scheme. The build printed
warnings about an absent Metal toolchain search path, but no errors. The full
`SortSymphony` Mac Catalyst scheme also built successfully.

The real app test launched the new build with `SORT_SYMPHONY_TRACE=1` using
`open -n -F --env`. Selecting Binary Insertion Sort caused the app to enter
`Recording…`; the host logged target PID 8375, `isRunning: 1`, zero run
issues, and saved
`/private/tmp/SortSymphonyTraces/sort-binaryinsertionsort-8375-1789932040826.trace`.
Exporting its `cpu-profile` table counted **406 sample rows**. This validates
the app-to-host handshake and an actual app-triggered trace.

One UI test initially produced no trace because UI automation attached to
an older installed `/Applications/SortSymphony.app` instance rather than the
new debug build. Selecting the build by its full bundle path resolved that
test setup mistake. The debug app received `SORT_SYMPHONY_TRACE=1`, confirmed
by inspecting PID 8375's environment.
After validation, the temporary loopback host was stopped with Ctrl-C and the
debug app instance (PID 8375) was terminated. The older installed app
instance was left alone.

Build the Swift variant (the module caches must be placed under `/private/tmp`
inside this Codex filesystem sandbox):

```sh
clang -fobjc-arc -DINSTRUMENTS_INJECT_BUILD -c \
  Tools/InstrumentsPrototype/probe.m -o /private/tmp/instruments-probe-bridge.o
clang -c Tools/InstrumentsPrototype/injected_entry.c \
  -o /private/tmp/instruments-injected-entry.o
swiftc -module-cache-path /private/tmp/instruments-swift-module-cache \
  -Xcc -fmodules-cache-path=/private/tmp/instruments-clang-module-cache \
  -emit-library -module-name InstrumentsPrototype \
  Tools/InstrumentsPrototype/RecordingSession.swift \
  Tools/InstrumentsPrototype/TraceTriggerServer.swift \
  /private/tmp/instruments-probe-bridge.o \
  /private/tmp/instruments-injected-entry.o \
  -o /private/tmp/instruments-swift-prototype.dylib \
  -F /Applications/Xcode.app/Contents/Applications/Instruments.app/Contents/Frameworks \
  -F /Applications/Xcode.app/Contents/SharedFrameworks \
  -framework CoreData -framework Security -framework InstrumentsPlugIn \
  -framework InstrumentsKit -framework InstrumentsTrace \
  -framework InstrumentsPackaging -framework DVTInstrumentsFoundation \
  -Xlinker -rpath \
  -Xlinker /Applications/Xcode.app/Contents/Applications/Instruments.app/Contents/Frameworks \
  -Xlinker -rpath -Xlinker /Applications/Xcode.app/Contents/SharedFrameworks
```

Run the Swift variant with a unique output URL:

```sh
env DYLD_INSERT_LIBRARIES=/private/tmp/instruments-swift-prototype.dylib \
  INSTRUMENTS_INJECT_RUN=1 \
  INSTRUMENTS_TARGET_EXECUTABLE=/private/tmp/instruments-busy-target \
  INSTRUMENTS_OUTPUT=/private/tmp/native-cpu-swift.trace \
  /Applications/Xcode.app/Contents/Developer/usr/bin/xctrace
```

The current Swift `RecordingSession.record()` supports `onStarted` and
`stopWhen` callbacks. `recordAsync` provides typed events/results after
main-thread initialization, with the package lookup thread caveat above.
`TraceTarget.attach` was exercised through the loopback host and real Mac
Catalyst app. The host stops on an app `STOP` message, with duration as a
fallback cap. The app hook traces `TapeFactory.makeTape`, which includes the
shuffle and selected sorting algorithm; the Runs picker can repeat it.

Start the loopback host after building the Swift library:

```sh
env DYLD_INSERT_LIBRARIES=/private/tmp/instruments-swift-prototype.dylib \
  INSTRUMENTS_INJECT_RUN=1 INSTRUMENTS_LISTEN_PORT=27727 \
  /Applications/Xcode.app/Contents/Developer/usr/bin/xctrace
```

Run the Mac Catalyst app with `SORT_SYMPHONY_TRACE=1` in its debug scheme's
environment **and** `LOCAL_INSTRUMENTS_TRACING` in Swift compilation
conditions. Its `SortSession.start(size:)` waits for `READY`, runs the selected
algorithm, sends `STOP`, waits for `DONE`, and stores the trace URL. A failed
connection is surfaced as a `SortSession` recording failure for manual runs.
The old manual build commands above remain a record of discovery; use
`build.sh` in `README.md` for a fresh build.

An `Allocations` template run began with no preflight issues and `isRunning`
became true, but the probe hung beyond one minute. A stack sample at
`/private/tmp/allocations-probe.sample.txt` showed the main thread in
`XRTraceCommandExecutor executeStopOnItinerary:` → `_startupInstruments:` →
synchronous XPC `mach_msg`. PID 5593 was terminated after the sample; it is no
longer running. `/private/tmp/native-allocations.trace` is incomplete (about
44 KB). The old template path may need different stop sequencing or an actual
allocation-producing target; do not count this as a successful trace.

The current `probe.m` still contains exploratory method-dump and registry
logging. A future cleanup can move that out of the recording bridge.

## Operational notes

- The app hook edits `Modules/SortFeature/Sources/SortSession.swift` and
  `SortView.swift`, and adds `DebugInstrumentsTrace.swift`.
  `Tools/InstrumentsPrototype/` is currently an untracked experimental
  directory; avoid altering other working-tree changes.
- Use `sandbox_permissions: require_escalated` for running Instruments tools in
  this Codex environment because they write under `~/Library/Caches`.
- `README.md` contains the build/sign instructions and TCC caveat.
- Keep reporting unusual failures, especially any permission or TCC denial.
- When finished with the experiment, restore the user's original security
  policy through the same boot-policy mechanism they used; this task did not
  make that change automatically.

## Suggested resumption sequence

1. Read this log, `README.md`, and the current `probe.m`; check the active
   boot policy again if the Mac has rebooted.
2. Run `Tools/InstrumentsPrototype/build.sh` for the working injected dylib.
   Only the separate standalone ad hoc probe needs signing with
   `Experimental.entitlements` after each rebuild.
3. Preserve the working injected route. For a cleaner standalone host later,
   investigate why only the signed carrier can
   acquire kernel trace resources. Do not assume TCC or kill `tailspind`
   merely because its PID appears in the error.
4. On each attempted fix, validate with
   `xcrun xctrace export --toc --input <path>`, then export the relevant table:
   `cpu-profile`, `time-profile`, or `FsSyscall`. Check duration, run issues,
   and actual rows. Short event-stopped traces are expected to be under one
   second. Exit status 9 flags known run issues or an early unrequested stop,
   but is not a complete trace validity check.
5. Remaining research: improve private-framework async thread affinity and find a
   standalone-host kernel trace authorization path. The source distribution
   and feedback/demo narrative are complete drafts; submitting or publishing
   them remains a user-controlled external action. Preserve the local compile
   flag for Cloud exclusion.
