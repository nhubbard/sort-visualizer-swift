# Xcode 27 profile invariants and option survey

Observed on macOS 27.0 with Xcode 27.0 (27A266a), using this Mac as the
recording device. This is a version-specific compatibility catalog for the
experimental declarative API. A rule marked **archive** comes from the exact
`.tracetemplate` selected by `XRTrace`; **UI** means the Instruments Next
Recording pane; **decoder** means `xctrace --recording-options` was invoked
with a nonexistent PID so no trace started; **recorded** means a saved trace
was exported and checked. These evidence levels must not be conflated.

Machine-readable inventories:

- `OptionsCatalog.json`: options and defaults for all 25 standard templates.
- `InstrumentOptionsCatalog.json`: options and defaults for all 63 standard
  instruments added individually to Blank.
- `TemplateComposition.json`: exact template path, constituent instrument IDs,
  and supported private target-type codes for each standard template.
- `InstrumentCapabilities.json`: private target-type support for each of the
  63 instruments when added alone to Blank.
- `TemplateArchiveCatalog.json`: recorder mode flags, limits, and archived
  command switch state from 31 installed `.tracetemplate` archives. Multiple
  archives can share a display name; use `TemplateComposition.json` to select
  the archive actually loaded by this Xcode installation.
- `NumericValidation.json`: observed decoder result for numeric boundary and
  type probes. Exit 21 means the options decoded and the intentionally
  nonexistent target was rejected; exit 57 means option decoding failed.
- `FilterValidation.json`: decoder outcomes for Allocations filter action,
  matcher, type string, and list shape.
- `TemplateRunValidation.json`: bounded baseline recording results; see
  individual entries for run issues and export status.
- `CompatibilityResults.jsonl`: resumable, per-case run evidence from the
  compatibility harness, including exported schemas, run issues, and cleanup.
- `MacCompatibility.json`: explicit macOS platform exclusions derived only
  from the baseline template and individual-instrument recordings.

The compatibility harness generated and classified all 5,398 cases in the
full finite matrix: 88 baselines, all 1,575 standard-template plus
one-instrument additions, all 1,953 two-instrument pairs, and all 1,782 option
variants. Final outcomes were 3,390 valid, 612 valid with warnings, 125
duplicates, 623 derived platform exclusions, seven direct platform
exclusions, 269 privacy skips, one privacy prompt, 94 recording errors, 74
resource-derived skips, 61 scratch-limit stops, 75 attached-target
rejections, and 67 timeouts.
Six Processor Trace additions were marked `resource-derived` without a run
after repeated timeouts and excessive ktrace scratch growth in neighboring
cases. Twelve exact additions were stopped by a 128 MiB scratch cap;
`scratch-limit` is a resource safety result, not proof of intrinsic
incompatibility. A passing pair does not establish that a larger instrument
set will work. Exact settings, warnings, and run issues are in
`CompatibilityResults.jsonl`.

The full Allocations option family is now classified separately: all 255
Boolean combinations across its six Allocations switches, Points of Interest
log exclusion, and VM Tracker automatic snapshots saved valid traces; its
one numeric sample also passed. This establishes run compatibility on the
CPU fixture, not the semantic effect of every switch or behavior on other
targets.

The complete CPU Counters option family has no hard rejection: all 511
Boolean combinations saved exportable traces (213 plain valid, 298 valid
with sampling-period warnings), and both numeric samples passed. The typed
Swift path saved all four CPU Counter Boolean settings together in
`form.template` and exported with zero run issues. A warning is not
classified as an invalid profile.

Leaks also completed its full finite option family: all 255 Boolean
combinations and its one numeric sample saved valid traces. This covers
Allocations switches inside the Leaks template, its automatic-snapshot
toggle, and Points of Interest log exclusion. The 100 ms fixture establishes
run acceptance, not that an automatic leak snapshot actually fired.

Game Memory completed its finite option family: all 120 remaining Boolean
combinations saved valid, exportable traces, completing the family. Its
settings combine Allocations and VM Tracker switches. As with Leaks, this
establishes that the recorder accepts these values on the short CPU fixture,
not that every optional feature produced measurable data.

The 64 Game Performance option cases yielded 19 valid traces, 38 valid traces
with nonfatal warnings, and seven scratch-limit stops. All seven capped cases
used a 100 ms Hangs threshold, while other combinations with that threshold
passed. The evidence therefore supports a resource-sensitivity warning for
short-threshold Game Performance profiles, not a deterministic rejection rule.

All 63 Game Performance Overview option cases are classified, including the
57 combinations added by the exhaustive sweep. Every case saved a valid,
exportable trace without warnings or scratch-limit stops.

All 64 Swift Concurrency option cases are classified. The 57 combinations
added by the exhaustive sweep all saved valid, exportable traces without
warnings or scratch-limit stops.

All 64 SwiftUI option cases are classified. Every one of the 57 exhaustive
additions saved an exportable trace with the expected nonfatal warning that
the synthetic CPU fixture contained no SwiftUI activity.

All 64 System Trace option cases are classified: 24 valid and 40 valid with
a nonfatal Time Profiler sampling-period mismatch warning. All were
exportable, with no scratch-limit or recording failure.

All 64 Time Profiler option cases are classified. Every one of the 57
exhaustive additions saved a valid, exportable trace without warnings or
scratch-limit stops.

Animation Hitches is strongly resource sensitive in this short-run harness:
of its 32 option cases, four were valid, two valid with warnings, and 26 hit
the 128 MiB scratch cap. These are resource results rather than declarative
incompatibilities. `DTServiceHub` also retained deleted files from stopped
recorders; see the storage abnormality in the investigation log.

All 31 Core AI option cases saved valid, exportable traces through xctrace's
recording-options path. A separate private native setter experiment produced
missing GPU counter issues, so that setter is not exposed by the typed API.

All 32 Metal System Trace option cases saved valid, exportable traces without
warnings or scratch-limit stops.

The first 200 new two-instrument cases in Blank yielded 167 valid, three
valid with warnings, 17 derived platform exclusions, seven privacy skips,
three resource-derived Processor Trace skips, three attached-target
rejections, and five recording errors. Four recording errors were the known
CPU Counters missing counting-mode prerequisite. Advanced Graphics
Statistics plus Metal Performance Overview failed twice at stop with a data
provider logging error. The generated catalog records that exact
two-instrument failure, and the declarative validator checks confirmed
pairwise failures among two explicitly added instruments.
After the next 300 pair cases, the generated set contains five confirmed
pair exclusions: CPU Profiler with Hitches, SwiftUI, or Metal Performance
Overview; Metal Performance Overview with Advanced Graphics Statistics or
Audio Statistics. A linked Swift consumer verified that explicitly adding
CPU Profiler and Hitches to Activity Monitor fails validation before a trace.
The completed pair matrix expands that generated set to 20 exact pair rules:
five repeatable recording failures and 15 scratch-limit combinations. The
scratch rules include Core Data activity with System Call Trace or Thread
Activity, several filesystem instruments with SwiftUI, and high-volume GPU
or Metal combinations. They are protective resource rules for this Mac and
128 MiB cap, rather than claims that Instruments can never record them.

The five excluded instrument IDs are `com.apple.dt.coreanimation-fps`,
`com.apple.dt.instruments.foveatedstreaming`,
`com.apple.dt.instruments.power-metrics`,
`com.apple.tdg.instruments.reality-metrics`, and
`com.apple.tdg.instruments.realityframes`. Core Animation FPS reports that
macOS has no Core Animation FPS metric; the others explicitly require
iOS/iPadOS or visionOS. HTTP Traffic paused at a privacy prompt; this is
not a TCC denial. `stdout/stderr` does not support private attached-process
target type 2 on this installation.

Eighteen option variants saved exportable traces with warnings: some Time
Profiler settings caused requested/configured `time-sample` period mismatches,
and the SwiftUI template said the CPU-only fixture had no SwiftUI data. Five
Processor Trace option variants timed out, including on retries; one retry
briefly reported a kperf lock conflict. Activity Monitor's complete
63-addition pass found 50 valid cases, one exportable SwiftUI-data warning,
two duplicates, five derived platform exclusions, two privacy skips, the CPU
Counters counting-mode error, a Processor Trace timeout, and the
`stdout/stderr` target-type rejection. Across tested parent templates,
CPU Counters additions failed 20 times with “No counting mode selected.”

Advanced Graphics Statistics failed with “This instrument doesn't support
Windowed Mode” when added to Audio System Trace or Game Performance. Both
template archives store a five-second `windowLimit` even though their
`recordingMode` field is `2` (Deferred). A disposable Audio template patched
to `windowLimit = 0` recorded that pair with zero run issues and exported
`graphics-statistic`. The typed `.captureLast(.disabled)` setting reproduced
the result for both templates. A typed one-second Capture Last run saved
`windowLimit = 1_000_000_000`, confirming nanosecond units. The Game
Performance run printed `DTXMessage ... unknown parameter type` diagnostics
despite zero run issues and a valid export; their cause is unknown.

Adding CPU Profiler to Animation Hitches, CPU Counters, Game Performance
Overview, Processor Trace, or SwiftUI produced repeatable hard errors. The
reverse CPU Profiler template plus Hitches, SwiftUI, Metal Performance
Overview, or Processor Trace also failed twice. Most reported a data-source
setup failure with a misleading suggestion to remove CPU Counters; the CPU
Counters parent reported a KPC table binding mismatch. The generated
validator excludes these nine exact hard pairs and twelve exact pairs that
crossed the scratch cap. Its four Windowed Mode exclusions are Audio System
Trace and Game Performance, each with Advanced Graphics Statistics or Sampler;
`.captureLast(.disabled)` can override those four window conflicts. The
two graphics-statistic overrides have saved and exported through the private
recorder; the two Sampler overrides have not yet been tested.

## Standard template structure

All 25 selected template archives advertise Deferred support. The table's
Immediate and Capture Last columns are archive capability flags; the GUI
confirmed disabled controls on File Activity, CPU Counters, Processor Trace,
and Leaks. Target codes are the private values passed to
`allInstrumentsSupportTargetType:forDevice:`. Code `2` was exercised for an
attached `PFTProcess`; code `1` was used by the prototype for all-processes;
code `0` has not yet been assigned a reliable user-facing meaning. All
templates reject code `3`. A `Y` is a capability report, not proof that a
trace will contain useful data for a given target.

| Template | Instruments | Immediate | Capture Last | Target 0 | Target 1 | Target 2 | Option groups |
| --- | ---: | :---: | :---: | :---: | :---: | :---: | --- |
| Activity Monitor | 2 | Y | Y | Y | Y | Y | — |
| Allocations | 3 | Y | N | N | Y | Y | Allocations, Points of Interest, VM Tracker |
| Animation Hitches | 6 | N | N | Y | Y | Y | Hangs, Time Profiler |
| App Launch | 7 | N | Y | Y | Y | Y | Time Profiler |
| Audio System Trace | 10 | N | Y | Y | Y | Y | Hangs, Points of Interest |
| CPU Counters | 4 | N | Y | Y | Y | Y | CPU Counters, Points of Interest, Time Profiler |
| CPU Profiler | 4 | Y | Y | Y | Y | Y | CPU Profiler, Hangs, Points of Interest |
| Core AI | 4 | Y | Y | Y | Y | Y | Core AI, Time Profiler |
| Data Persistence | 3 | Y | Y | Y | Y | Y | — |
| File Activity | 4 | N | Y | Y | Y | Y | — |
| Foundation Models | 1 | Y | Y | Y | Y | Y | — |
| Game Memory | 6 | Y | N | N | Y | Y | Allocations, VM Tracker |
| Game Performance | 12 | N | Y | Y | Y | Y | Hangs, Points of Interest, Time Profiler |
| Game Performance Overview | 3 | N | Y | Y | Y | Y | Metal Performance Overview, Time Profiler |
| Leaks | 3 | Y | N | N | Y | Y | Allocations, Leaks, Points of Interest |
| Logging | 2 | Y | Y | Y | Y | Y | os_log, os_signpost |
| Metal System Trace | 7 | Y | Y | Y | Y | Y | Hangs, Time Profiler |
| Network | 3 | Y | Y | Y | Y | Y | Points of Interest |
| Power Profiler | 6 | N | Y | N | Y | Y | Metal Performance Overview, Time Profiler |
| Processor Trace | 3 | N | N | N | Y | Y | Points of Interest, Processor Trace |
| RealityKit Trace | 7 | Y | Y | Y | Y | Y | Hangs, Time Profiler |
| Swift Concurrency | 6 | Y | Y | Y | Y | Y | Hangs, Points of Interest, Time Profiler |
| SwiftUI | 4 | N | N | Y | Y | Y | Hangs, SwiftUI, Time Profiler |
| System Trace | 11 | N | Y | Y | Y | Y | Hangs, Points of Interest, Time Profiler |
| Time Profiler | 4 | Y | Y | Y | Y | Y | Hangs, Points of Interest, Time Profiler |

For arbitrary added instruments, target-type support is the intersection of
their individual capabilities. This was checked with CPU Profiler plus
`stdout/stderr`: the pair retained only target code `1`, matching the two
individual reports. `stdout/stderr` alone supports code `1` but not `0` or
`2`. Leaks, VM Tracker, Allocations, Location Energy Model, Processor Trace,
and Sampler also reject code `0`; the full set is in
`InstrumentCapabilities.json`.

## Recorder and option invariants

- **Mode values:** Patching `XRRecordingOptions.recordingMode` in a temporary
  Time Profiler template and exporting one-second traces mapped values `0`
  and `1` to Immediate and `2` to Deferred. Value `3` timed out and was
  terminated. Treat only `1` and `2` as intended values in the typed API.
  A File Activity template patched to Immediate (`1`) saved a trace as
  Deferred with zero run issues: Instruments silently coerced the unsupported
  request. An explicit declarative Immediate request should fail validation.
- **Time units:** The template archive stores 12 hours as
  `43_200_000_000_000` and five seconds as `5_000_000_000`, consistent with
  nanoseconds. This is an inference from UI limits and archived values; the
  exact private setter contract still needs a round-trip test.
- **Complete option documents:** `--recording-options` requires the whole
  template JSON from `--show-recording-options`. A partial document fails
  decoding with exit 57. Wrong types also fail with exit 57. Unknown keys
  can be silently ignored while producing a valid trace, so the Swift API
  should reject unknown options itself. `--show-recording-options` ignores
  any supplied option file, even malformed JSON; it is an inventory command
  only.
- **Template-specific defaults:** Time Profiler enables
  `recordWaitingThreads` and `contextSwitchSampling` in App Launch, and
  enables `highFrequencySampling` in SwiftUI. Hangs thresholds vary across
  templates (33, 100, 250 ms). CPU Counters added alone has no selected
  counting mode, while its standard template supplies one. Do not replace
  template defaults with a universal per-instrument default.
- **Numeric fields:** See the exact probes in `NumericValidation.json`.
  `hangsThreshold`, CPU Counters `pmiThreshold` and `processBucketSize`, and
  Core Animation Commits `expensiveCommitSampling` decode nonnegative JSON
  integers in tested cases. Leaks and VM Tracker `snapshotIntervalInSeconds`
  decode tested signed integers. Processor Trace `bufferSizeFill` and
  `bufferSizeWrap` decode tested signed or fractional JSON numbers. Decoder
  acceptance does **not** establish a safe operational range. A hang
  threshold of `0` and `251` ms produced valid traces and appeared exactly
  in exported settings; the UI's 33/100/250/500 ms values are presets, not
  the only representable values. The Processor Trace UI labels a default
  buffer limit of `1 GiB`, accepts `0`, `-1`, and `1.5` as text without
  immediate validation, and labels its throttle option “Prevent Data Loss.”
  The eight numeric instrument-option keys in the 63-instrument catalog are
  now represented in typed settings: CPU Counters' two integers, Core
  Animation Commits' sampling level, Hangs' preset threshold, Leaks' snapshot
  interval, Processor Trace's two buffers, and VM Tracker's interval.
  Processor Trace's private stop lifecycle remains unusable, so its typed
  buffers are mapped but not end-to-end verified. The recorder-level
  `windowLimit` is separately exposed as `CaptureLast`.
- **Private Hangs enum:** The archived command value is a preset code rather
  than milliseconds: `0 → 500 ms`, `1 → 250 ms`, `2 → 100 ms`, and
  `3 → 33 ms`. Each mapping was verified by patching a temporary Time
  Profiler template and exporting the resulting trace. Values `-1`, `4`,
  and `99` silently normalized to the 100 ms preset in these runs. Reject
  out-of-range values in the typed API. CLI JSON accepts arbitrary tested
  nonnegative millisecond values, including `0` and `251`, so the CLI and
  private archive representation are not interchangeable.
- **Private snapshot units:** The Leaks template data contains
  `com.apple.instruments.leaks.XRLeakConfigurationCheckIntervalKey =
  10_000_000` for its ten-second default. VM Tracker contains
  `XRVMInstrumentKey_snapRateMicros = 3_000_000` for its three-second
  default. These are microsecond values. Both keys are in per-instrument
  template data, separate from the command's global switch state. Mutation
  and exported-run verification of nondefault values remain to be done.
- **Allocation filters:** The default `recordedTypes` list contains one
  enabled `record` rule for all types (`contains: "*"`) and disabled `ignore`
  rules for NS, CF, and Malloc prefixes. The UI says later rules override
  earlier ones. Rule ordering, match type, action, and enabled state belong
  in a typed model. The decoder accepted `record` and `ignore` actions and
  `contains` and `hasPrefix` matchers; tested alternatives (`exclude`,
  `include`, `equals`, `regex`, `exact`, empty, and arbitrary strings) failed.
  An empty type string, an empty rule list, and duplicate rules decoded, but
  their recording semantics are unverified. A `nil` or numeric type failed.
  The typed API should require at least one enabled record rule and reject
  duplicate rules before recording.
- **Snapshot controls:** Leaks defaults to automatic snapshots every 10
  seconds and offers a manual mode in the UI. VM Tracker defaults to a
  three-second interval in the option JSON. The declarative API should model
  automatic/manual as a choice and require an interval only for automatic.
  A temporary Leaks template patched from `10_000_000` to `2_000_000`
  microseconds loaded and saved an exportable 500 ms trace, but that trace
  ended before a snapshot and did not prove the changed cadence.
- **CPU Counters configuration:** The GUI offers Guided and Manual. Guided
  requires a selected hardware counting mode; adding CPU Counters alone to
  CPU Profiler produced “No counting mode selected.” The CPU Counters
  template defaults to “CPU Bottlenecks.” This Mac's guided picker also
  lists instruction delivery/processing bottlenecks, discarded sampling,
  L1D miss sampling, SME bottlenecks, and instruction characteristic/metric
  groups. These choices depend on the current processor and should be
  discovered at runtime rather than hardcoded as a universal enum. Manual
  mode offers sampling by time or events; event mode showed a default
  `CORE_ACTIVE_CYCLE` event and `1_000_000` events per sample in the UI.
- **Encoded numeric options:** CPU Counters and Processor Trace put their
  option dictionaries in the instrument's `recordingControlState.state` under
  `optionsEncoded`, as UTF-8 JSON bytes in the binary template archive. The
  stock CPU Counters value contains `pmiThreshold: 1_000_000` and
  `processBucketSize: 10`; a bounded trace recorded with CLI
  `pmiThreshold: 2_000_000` saved `2_000_000` in that same archive slot.
  Processor Trace's stock value contains `bufferSizeFill: 1`,
  `bufferSizeWrap: 1`, `throttleEnabled: true`, and `ringBufferMode` set to
  `fill`. The Processor Trace numeric values have not been run-tested because
  its stop lifecycle has hung in earlier tests. The temporary CPU trace was
  removed.
- **Core Animation Commits:** Adding this instrument to Blank and recording
  with `expensiveCommitSampling: 1` saved that exact integer in its own
  `optionsEncoded` JSON blob, while the generic
  `sampleExpensiveCACommits` command switch stayed `0`. The decoder accepted
  tested values `0`, `1`, and `2`; it rejected `-1` and `1.5`. This option
  is not yet in the Swift facade because the current archive patcher runs
  before additional instruments are added. Its bounded test trace was
  deleted. Processor Trace's standalone added-instrument default is
  `bufferSizeFill: 4`, whereas the standard Processor Trace template
  defaults to `1`; template context must be preserved.

## Combination outcomes checked with saved traces

The 500 ms baseline sweep on an attached disposable CPU fixture produced
**19 exportable traces** from the 25 standard templates. Two templates were
skipped because of earlier stop hangs (`Allocations`, `Processor Trace`).
Subsequent hard-bounded 100 ms CLI runs of both templates completed and
exported. A matching 100 ms private Allocations run also completed and
exported. The private Processor Trace run still reported `isRunning=1` after
the wrapper's 15-second stop wait; its saved bundle failed export with a
fatal run error. The wrapper now reports `stopTimedOut` for that state, and
the typed local-Mac plan validator rejects Processor Trace before recording.
`Power Profiler` failed with the explicit run issue “not supported on macOS;
record on iOS or iPadOS instead.” `RealityKit Trace` failed because its
Frames and Metrics instruments require visionOS. `Foundation Models` and
`Network` paused at interactive privacy warnings before recording, which
caused the automated timeouts; neither was a TCC denial. Foundation Models
warns that prompts and responses are stored unencrypted in the trace and
system logs. Network warns that all HTTP traffic on this Mac, including
potentially sensitive values, can be captured during and for up to 60 seconds
afterward. The survey did not bypass those warnings. Their temporary bundles
and fixture processes were removed. See `TemplateRunValidation.json` for the
per-template export outcome; the privacy-warning diagnosis was obtained in
separate bounded reruns.

| Combination | Result | Evidence |
| --- | --- | --- |
| CPU Profiler + Filesystem Activity | Valid | 1 CPU row and 3,738 filesystem syscall rows in a 1.47-second trace. |
| CPU Profiler + Time Profiler | Valid | One 1.64-second trace exported both `cpu-profile` and `time-profile` schemas. |
| CPU Profiler + CPU Counters (default added instrument) | Invalid as configured | Preflight issue: “No counting mode selected”; saved bundle could not be exported as a valid trace. The CPU Counters standard template supplies a mode. |
| CPU Profiler + Processor Trace | Invalid as configured | Run issues: “Unsupported configuration of Instruments is being used. Remove Instruments recording CPU Counters from the document” and data source setup failure. A saved bundle could be exported, but it represents a failed run. |
| Time Profiler + Processor Trace | Unresolved | `xctrace` did not finish within 20 seconds for a one-second request; it was terminated. |

`PFTInstrumentList verifyCommand:error:` returned success for all four tested
additions to CPU Profiler, including the two that later failed preflight.
Neither this method nor `--show-recording-options` is a sufficient
compatibility validator. Runtime checks must inspect run issues and exported
data. The temporary pairwise traces and fixture processes were removed.

## Private option-setting route

`XRInstrument.currentRecordSettingsDetailMetaUI` and
`recordingParametersInScope` returned empty arrays immediately after loading
templates. KVC mutations of `XRInstrumentControlState` on a copied command,
the template command, and the instrument object read back correctly but did
not change the exported trace options. A temporary copy of the binary
`NSKeyedArchiver` Time Profiler template, with the command's
`recordWaitingThreads` value patched from `false` to `true`, loaded through
`XRTrace.loadTemplate:outputURL:preserveRunHistory:error:` and produced a
valid trace with `record-waiting-threads="1"`. This is the verified bridge
from a typed option value to this private framework. The original template
remained untouched. Other option key mappings require the same round-trip
check before being exposed as stable typed settings. For CPU Counters and
Processor Trace, `optionsEncoded` is an instrument-local JSON data blob,
not a standalone integer KVC field.

## Declarative wrapper status

`TracePlan.build` now accepts typed `TraceSetting` directives, including
optional branches and loops. It rejects duplicate settings groups, settings
absent from a known standard template, unsupported Immediate mode, and
nonpositive or nonfinite intervals/buffer sizes. Its archive patcher copies
the installed template to a temporary file, updates only selected switches
or instrument data, and deletes that file after recording. Saved traces
confirmed `record-waiting-threads=1`, `high-frequency-sampling=1`, CPU Counters
`pmiThreshold=2000000`, and Leaks snapshot interval `1000000` microseconds.
An async Time Profiler run also saved `record-waiting-threads=1`, and a
declarative Immediate CPU Profiler run exported `<recording-mode>Immediate`.
In final combined checks, Time Profiler exported all four requested switches
as `1` and Hangs exported a `33` ms threshold. CPU Profiler exported high
frequency and kernel callstacks as `1`, with the same 33 ms Hangs threshold.
The Game Memory template saved a VM Tracker interval of `1_000_000`
microseconds with automatic snapshots enabled. Leaks manual mode saved its
auto-snapshot flag as `false`. These short runs verify the stored settings;
they do not establish the actual number or cadence of snapshots.
Time Profiler high frequency required both archived `highFrequency` and
`highFreqSampling` switches; setting either one alone saved a trace that
still reported high frequency off. No diagnostic trace or copied template
from these checks remains.

`TraceTemplate` offers named cases for the 23 standard templates that did
not report explicit macOS platform failures. Power Profiler and RealityKit
Trace are omitted; the validator also rejects them through the low-level
`.named(String)` escape hatch. That escape hatch remains for experimental
templates outside the catalog.

The typed API deliberately exposes only mapped settings. The complete
catalogs also include other groups such as Core AI, os_log, SwiftUI, and
allocation filters, whose effective private setters have not yet been
verified. Those options should gain typed cases only after an archive patch
and a saved-run check. Runtime target/device and instrument-pair failures
remain possible even for a plan that passes static validation.

Points of Interest `excludeOSLogs` and Hangs
`detectPriorityInversions` need a different setter from the archived command
switches. Patching the switches alone exported `false`; inserting native
`optionsEncoded` blobs into the template before load reset other Time Profiler
settings. The working route is to set UTF-8 JSON `optionsEncoded` on each
loaded `XRInstrument.recordingControlState` after `loadTemplate:` and before
`startCommand:`. A combined declarative trace then exported POI
`excludeOSLogs=true`, Hangs `detect-priority-inversions=1`, a 33 ms Hangs
threshold, and all four Time Profiler switches as `1`. These native options
are now exposed as typed settings. The setter returns an error when the
requested instrument is absent.

## Remaining compatibility work

The catalogs enumerate every standard template and instrument installed on
this Mac, but they do not prove every pair or every numeric magnitude safe.
Processor Trace has a confirmed private-recorder stop hang; avoid large
automated pairwise runs until that lifecycle is understood. Allocations
completed a 100 ms private run, but longer captures still need testing.
Probe custom allocation
rule enums and CPU
counter mode variants, then exercise high-value added-instrument pairs using
short, bounded traces. Record a conflict only when UI, archive, preflight,
or exported trace evidence supports it, with the evidence level stated.
