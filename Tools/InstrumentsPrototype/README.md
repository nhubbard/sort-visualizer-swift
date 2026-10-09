# Xcode 27 private Instruments recording probe

This is an experimental local probe for Xcode 27.0 (27A266a). It does not ship with Sort Symphony.
See [INVESTIGATION_LOG.md](INVESTIGATION_LOG.md) for the running play-by-play,
working setup, and remaining limitations.

## Documentation map

- `RecordingSession.swift` is the public API entry point. Its DocC comments
  describe plans, builder directives, targets, synchronous and asynchronous
  recording, callbacks, cancellation, results, and typed failures.
- `TraceSettings.swift` documents every public settings type and the rule that
  `nil` preserves the installed template's value.
- `PROFILE_INVARIANTS.md` is the evidence-backed compatibility reference for
  templates, instruments, settings, numeric probes, and invalid combinations.
- `TraceTriggerServer.swift`, `probe.m`, and `injected_entry.c` document the
  loopback protocol, private recorder lifecycle, and signed-carrier boundary.
- `INVESTIGATION_LOG.md` preserves the chronological experiments and abnormal
  behavior. `DEMO_NOTES.md` contains the Apple Feedback and Show HN drafts.

The Swift module can be opened in Xcode for Quick Help. Public declarations
use `///` documentation comments; implementation comments concentrate on the
private framework behavior that is not apparent from the code itself.

## Compatibility harness

`compatibility_harness.py` records bounded, disposable traces against the
installed Xcode. It catalogs all 25 standard templates and all 63 registered
instruments, then generates template plus instrument, two-instrument, and
option-variant cases. It attaches each case to a fresh CPU fixture, exports the
trace table of contents, records errors and warnings in
`CompatibilityResults.jsonl`, and removes the trace and fixture afterward.
The results file is append-only and keyed by case ID, so an interrupted survey
resumes without repeating finished cases. A file lock prevents simultaneous
writers, and an interrupted partial final line is repaired before the next
run. Pass `--retry-status timeout
unverified` to revisit inconclusive results. `--summary` reports the latest
status for each selected case; `--only-template 'CPU Profiler'` narrows a
diagnostic rerun, and `--only-instrument 'CPU Profiler'` narrows by addition.
`--cross-template-order` walks each added instrument across
templates before moving to the next one; it changes only execution order,
not case IDs or resumption. `--confirm-errors` immediately retries new hard
recording errors once, except the known missing CPU counting mode. For example:

```sh
python3 Tools/InstrumentsPrototype/compatibility_harness.py \
  --matrix all --full-booleans
python3 Tools/InstrumentsPrototype/compatibility_harness.py \
  --matrix all --full-booleans --run --write-macos-filter \
  --continue-after-scratch-limit --reclaim-deleted-scratch \
  --max-deleted-scratch-mib 64
```

The harness writes a sibling environment manifest containing the Xcode build,
macOS version, and architecture. If that environment changes, start a new
result file with `--results <path>` so observations from different installs
are not merged. It also checks that the four source catalogs match the
selected Xcode build; recatalog them before surveying another build.

The full finite matrix contains 5,398 cases in this installation, and the
checked-in result stream now classifies all 5,398. The first command prints
its size without recording. The second can take hours; it is safe to interrupt
and resume with the same command. Defaults are 100 ms per trace and a
20-second recording timeout. The harness also stops a case when
its Instruments scratch files exceed 128 MiB, stops the survey if free disk
falls below 40 GiB, and removes scratch `instruments*.ktrace` files created
by each case. Instruments ignores the scoped `TMPDIR` for some scratch files,
so the harness watches its global temporary directory too. Set
`--max-scratch-mib` and `--min-free-gib` to stricter limits if needed.
`--continue-after-scratch-limit` keeps a long survey moving after an
over-limit case has been stopped, recorded, and cleaned; the free-space floor
is checked again before the next case.
`DTServiceHub` can keep deleted ktrace files open after their directory entries
are removed. The harness therefore measures deleted-open ktrace storage after
each case and stops at 512 MiB by default. Pass
`--reclaim-deleted-scratch` to send TERM to only the retaining DTServiceHub;
Instruments relaunches that service as needed. During this survey one long
lived service retained 3,911 deleted files totaling 367.34 GiB. Restarting it
released the space immediately. A 64 MiB deleted-open cap is recommended for
resource-heavy option families.
The repeated Processor Trace combination timeouts and high scratch use are
recorded as `resource-derived` skips for untested combinations by default;
`--include-resource-unsafe` opts back into those recordings and the observed
Game Performance plus VM Tracker hazard. These skips are evidence-based
safety decisions, not claims of a macOS platform restriction.
Foundation Models, Network, and HTTP
Traffic are skipped unless `--include-sensitive` is supplied because their
recorders can capture prompts, responses, or network traffic. That flag also
passes `--no-prompt` to `xctrace`. The survey tests one nondefault sample for
each numeric field; it cannot exhaust unbounded numeric domains, all possible
instrument subsets, target apps, or run durations.

`--write-macos-filter` generates `MacCompatibility.json` and the Swift
`MacCompatibility.generated.swift` set. Its **platform exclusions** come
only from explicit baseline errors; all 88 baseline cases must exist before
regeneration. It also generates exact exclusions from Windowed Mode errors,
repeatable hard failures, and scratch-limit stops in template additions, plus
repeatable hard or scratch-limit failures in two-instrument Blank runs.
The typed plan validator uses this filter to reject the two incompatible
standard templates, five incompatible instruments, and observed incompatible
additions and confirmed explicitly added instrument pairs before starting a
recorder. Derived platform failures in combinations do not
expand the baseline exclusion set. Regenerate the catalog and results after an
Xcode update; these observations apply to Xcode 27.0 (27A266a) on macOS 27.0.

**Working prototype:** `injected_entry.c` loads the typed Swift
`RecordingSession` in Apple's signed `xctrace` process, exits before its CLI
runs, and records a real two-second CPU trace. A CPU-bound test exported 7,349
sample rows through the Swift wrapper. The exact build and run commands are in
the investigation log. The standalone ad hoc signed binary still cannot
acquire kernel trace resources on this Mac.

`TraceTriggerServer.swift` keeps the signed carrier listening on loopback.
The Mac Catalyst Debug app sends a request from `SortSession.start(size:)`
when built with `LOCAL_INSTRUMENTS_TRACING` and run with
`SORT_SYMPHONY_TRACE=1`. It waits for `READY`, records that sort's tape, then
collects `DONE` and displays the trace in a small SwiftUI history. The UI can
record repeatedly on the same PID and select CPU Profiler, Time Profiler,
File Activity, Activity Monitor, Allocations, Leaks, Swift Concurrency,
SwiftUI, Logging, System Trace, Data Persistence, CPU + File Activity, or
CPU + Signposts. The complete picker has 21 choices: 19 validated standard
macOS templates and the two combined CPU recipes.
The history is shared across algorithm screens and persisted
for later app launches; new rows show the captured PID so repeated traces on
the same process are visible. Older saved rows without a PID still decode.
An **All traces** sheet lists the full retained history, beyond the three
recent links in the compact control.
It sends `STOP` when tape generation finishes, with a duration
cap if the signal never arrives. The **Runs** picker repeats fast algorithms
inside one trace; a 50-run Binary Insertion Sort capture produced 49 CPU
profile rows. The original CPU, Time, and File Activity templates produced
trace data; see the log for
sample counts and limitations.

CPU Profiler, Time Profiler, CPU + File Activity, and CPU + Signposts expose a
**High Frequency** toggle in the Mac Catalyst Debug control. The loopback host
turns that into a validated `TraceSetting` and records the choice in trace
history. Older saved history entries still decode because the new field is
optional.

Build the local Mac Catalyst app with
`SWIFT_ACTIVE_COMPILATION_CONDITIONS='DEBUG LOCAL_INSTRUMENTS_TRACING'`.
The trace socket code and UI are absent from ordinary builds, including
Xcode Cloud builds, unless that flag is deliberately supplied.

## Local quick start

The prototype is self-contained under `Tools/InstrumentsPrototype`. To make
a source archive for another Xcode 27 Mac, run
`Tools/InstrumentsPrototype/package.sh [output.tar.gz]`. Unpack it anywhere
and run its `build.sh`; the script finds the selected Xcode through
`xcode-select`. The archive includes this project's MIT license and the
version-specific compatibility
catalogs and investigation record. It does not contain recorded `.trace`
bundles. This is a source distribution of the experiment, not a portable
binary artifact; private framework paths and behavior need verification on
each host.

From the repository root:

```sh
Tools/InstrumentsPrototype/build.sh
Tools/InstrumentsPrototype/run-host.sh
```

Run the Mac Catalyst Debug app with `LOCAL_INSTRUMENTS_TRACING` in its Swift
compilation conditions and `SORT_SYMPHONY_TRACE=1` in its environment. The
trace controls then appear above the sort canvas. `build.sh` emits a reusable
Swift module and dynamic library under `/private/tmp/instruments-prototype-build`
by default; set `INSTRUMENTS_BUILD_DIR` to change that output directory.
The host accepts 21 app choices on loopback, one recording at a time: 19
validated macOS templates plus CPU + File Activity and CPU + Signposts. App Launch is omitted
because this client attaches to an already-running app; Foundation Models
and Network are omitted for privacy; Power Profiler and RealityKit Trace are
excluded on macOS; Processor Trace is omitted because its stop lifecycle is
resource unsafe. The typed library also exposes selected
additional instruments, including Hangs, Points of Interest, Allocations,
Swift Tasks, and filesystem activity. It rejects duplicates using the
selected template's captured instrument IDs. The private bridge checks
whether the resulting instrument list supports the requested target type
before recording. The host accepts only typed identifiers; unknown IDs fail
before Instruments starts.
For a token-protected session, set `INSTRUMENTS_TRACE_TOKEN` on the host and
the same value as `SORT_SYMPHONY_TRACE_TOKEN` on the app. A mismatched or
missing token receives `ERROR unauthorized` before tracing starts. Without
the host variable, the loopback listener accepts local requests, so stop the
host when profiling is finished.
The app persists trace metadata in `UserDefaults`; the host's default trace
files are under `/private/tmp/SortSymphonyTraces` and may be removed by the
system. Set `INSTRUMENTS_OUTPUT_DIRECTORY` on the host for durable files.

The app's `Runs` picker repeats tape generation 1, 10, 50, or 100 times
within a trace and plays back the final tape. This helps fast algorithms
produce samples. Logging and CPU + Signposts dynamically enable the
`com.nhubbard.SortSymphony` subsystem before the app lazily constructs its
signposter. A private CPU + Signposts control exported four raw signpost rows,
one completed interval, and 4,354 CPU samples from the same recording.

The opt-in `DebugInstrumentsTrace.run` function is public from `SortFeature`
in that Mac Catalyst Debug configuration. An app call site can wrap a single
synchronous event with a label; it waits for `READY` before running the closure
and sends `STOP` when the closure returns or throws:

```swift
#if DEBUG && targetEnvironment(macCatalyst) && LOCAL_INSTRUMENTS_TRACING
let (value, traceURL) = try DebugInstrumentsTrace.run(label: "cache-refresh") {
    try refreshCache()
}
#endif
```

The closure runs on its caller's thread. Use a detached task for CPU-heavy
work that should not block the SwiftUI main actor. Tape generation uses this
public wrapper and emits the `Tape generation` interval.

`RecordingSession.swift` and `TraceSettings.swift` contain a reusable
declarative facade. The settings builder preserves the installed template's
defaults for omitted fields and validates template membership, duplicate
settings groups, unsupported Immediate mode, and numeric bounds before
Instruments starts. For example:

```swift
let plan = try TracePlan.build {
    TraceTemplate.cpuProfiler
    TraceInstrument.filesystemActivity
    TraceTarget.attach(pid: pid, executable: executableURL)
    Duration.seconds(2)
    TraceOutput(outputURL)
}
let result = try await RecordingSession(plan: plan).recordAsync { event in
    // .started or .completed(RecordingResult)
}
```

For a narrowly configured Time Profiler run:

```swift
let plan = try TracePlan.build {
    TraceTemplate.timeProfiler
    TraceTarget.attach(pid: pid, executable: executableURL)
    Duration.seconds(2)
    TraceOutput(outputURL)
    TraceSetting.timeProfiler(.init(
        highFrequencySampling: true,
        recordWaitingThreads: true
    ))
    TraceSetting.hangs(threshold: .milliseconds100,
                       detectPriorityInversions: true)
    TraceSetting.pointsOfInterest(excludeOSLogs: true)
}
```

Windowed templates can use `TraceSetting.captureLast(.last(.seconds(5)))`
or `.captureLast(.disabled)`. Audio System Trace and Game Performance reject
an added Advanced Graphics Statistics instrument under their stock
five-second window. A plan with `.captureLast(.disabled)` passes validation;
both combinations saved exportable traces through the private recorder.
The archive records window durations in nanoseconds, verified with a saved
one-second selection. Capture Last is validated against the selected
template's archived capability flags.

The wrapper makes a disposable copy of the selected Xcode template, patches
its archived settings, loads that copy with `XRTrace`, applies native
instrument options to the loaded control state, and deletes the copy after
the run. It does not modify Xcode's installed templates. Verified
end-to-end settings include Time Profiler high frequency and waiting threads,
CPU Counters PMI threshold, and the saved Leaks snapshot interval. The
typed Core Animation Commits setting accepts only the decoder-verified
sampling levels 0, 1, and 2. A private-recorder run saved level `1` in its
`optionsEncoded` JSON and exported Core Animation Commits schemas. The facade
also maps CPU Counters' four Boolean recording switches, alongside its PMI
threshold and process bucket size. One private-recorder run saved all four
requested Boolean values in `form.template` and exported without a run issue.
The facade
also exposes Boolean settings for Allocations, Metal Performance
Overview, SwiftUI layout tracing, `os_log`, and `os_signpost`. Those new
native-control setters have saved their values in exportable private-recorder
traces. Allocations also exposes ordered `AllocationTypeFilter` values whose
actions (`record` or `ignore`) and match modes (`contains` or `hasPrefix`)
are closed enums derived from decoder tests. A private run persisted two such
rules in `form.template` and produced an exportable trace. Core AI's
suffix-consolidation switch remains unavailable in the
typed facade: setting it to false twice caused GPU-device run issues through
the private setter, although the same CLI option recorded successfully. The
Processor Trace buffer fields are mapped to its encoded option blob but its
recording lifecycle still needs work. See [PROFILE_INVARIANTS.md](PROFILE_INVARIANTS.md)
for all 25 template capabilities, 63 instrument target capabilities, invalid
combinations observed, numeric decoder probes, and evidence levels.

The async method initializes Instruments on the main actor, then runs the
blocking Objective-C recorder on a serial Dispatch queue. A real Time Profiler
run through it produced 1,547 profile rows. Xcode 27 emits package lookup
thread warnings on that queue; a main-queue attempt failed to start a run.
Treat this async path as experimental. The synchronous bridge and
app-triggered path are verified. A later 100 ms private Allocations run
completed and exported; longer captures still need a lifecycle check.
Task cancellation requests a stop at the recorder's next poll, removes the
partial bundle, and throws `RecordingError.cancelled`; this was verified in a
live two-second cancellation of a ten-second request. A stalled private
preflight may still wait for its framework timeout.
Processor Trace remains unavailable in the typed local recorder because its
private stop did not complete and the saved bundle failed export.

The combined CPU + File Activity recipe was verified through the typed
loopback host: a 1.47-second trace exported 1 `cpu-profile` row and 3,738
`FsSyscall` rows. The fixture mostly waits between filesystem operations, so
its CPU sample count is low. A trace's metadata may contain the target's
environment variables; avoid sharing trace bundles without reviewing them.
Activity Monitor also saved successfully from a two-second CPU fixture run,
with 1 `activity-monitor-process-ledger` row and 2
`activity-monitor-process-live` rows. Its low sampling rate makes it less
useful for very short algorithm events.

The combined CPU + Signposts recipe was verified through the typed private
recorder. Its fixture exported 4 raw `os-signpost` rows, 1 completed
`OSSignpostIntervals` row, and 4,354 `cpu-profile` rows. The signposter must be
constructed after the recorder's `READY` acknowledgement because unified
logging caches dynamic subsystem enablement when the signposter is initialized.

## What was verified

- `XCTraceCore` is the small `xctrace` front end. Recording is implemented in
  `InstrumentsPlugIn`, `InstrumentsTrace`, and `DVTInstrumentsFoundation`.
- `PFTInitializeSharedFrameworks(NSUInteger mode, id issueResponder)` is needed
  before template lookup. On Xcode 27, mode `8` registers modern native
  instruments; mode `0` or `1` leaves CPU Profiler as a deprecated stub.
- `XRTrace.templateItemMatchingName:` finds the Time Profiler template.
- `XRTrace.loadTemplate:outputURL:preserveRunHistory:error:` loads it. The `.trace`
  output directory must exist first: `setOutputURL:` converts the argument to a
  file-reference URL and returns `nil` for a nonexistent path.
- `XRTrace.templateRecordCommand` supplies a command with purpose `Trace` (1).
  Its target can be set to a `PFTProcess` created for `XRLocalDevice.sharedDevice`.
- `XRTrace.startCommand:` queues an asynchronous preflight. A `true` return is
  **not** proof that recording started. Check `isRunning`, run issues, and the
  exported trace contents.
- The unsigned probe reached preflight, but `DTServiceHubClient` returned no
  connection. The run issue was `Error connecting to DTServiceHub`. A package
  saved afterward contained no run data; `xctrace export --toc` called it
  malformed.
- An Apple-signed `xctrace record` control run on the same Mac produced a valid
  trace. Its binary has `com.apple.private.DTServiceHubClient` and
  `com.apple.private.dt.instrumentsxpc.allowed` entitlements.
- Ad hoc signing a copy of the probe with those keys produced a valid on-disk
  signature, but AMFI killed it at launch: `The file is adhoc signed but
  contains restricted entitlements` (AppleMobileFileIntegrityError -424).
- After the user's AMFI boot-policy change, the probe launches and connects to
  DTServiceHub. CPU Profiler preflight/early recording also required
  `com.apple.private.logging.diagnostic`, `.stream`, and `.admin`; these are in
  `Experimental.entitlements`.
- Direct CPU recording still ends with “Failed to acquire kernel trace
  recording resources (Connection refused). Possibly in use by pid …” where
  that PID was `tailspind` when the probe runs as a standalone ad hoc binary.
  Running the same direct framework code inside Apple-signed `xctrace` succeeds.
  See the running log for comparisons and the working route.

## Build the direct probe

```sh
clang -fobjc-arc -framework Foundation -framework CoreData -framework Security \
  -F /Applications/Xcode.app/Contents/Applications/Instruments.app/Contents/Frameworks \
  -F /Applications/Xcode.app/Contents/SharedFrameworks \
  -framework InstrumentsPlugIn -framework InstrumentsKit \
  -framework InstrumentsTrace -framework InstrumentsPackaging \
  -framework DVTInstrumentsFoundation \
  -Wl,-rpath,/Applications/Xcode.app/Contents/Applications/Instruments.app/Contents/Frameworks \
  -Wl,-rpath,/Applications/Xcode.app/Contents/SharedFrameworks \
  Tools/InstrumentsPrototype/probe.m -o /private/tmp/instruments-probe
```

The probe can attach to a PID or spawn `/bin/sleep` itself with `-` as the PID:

```sh
/private/tmp/instruments-probe - /bin/sleep /private/tmp/native-probe.trace
```

## Entitlement experiment

The keys tested are in `Experimental.entitlements`. Applying them to a copy of
the probe is reversible; it does not change Xcode or macOS:

```sh
codesign --force --sign - \
  --entitlements Tools/InstrumentsPrototype/Experimental.entitlements \
  /private/tmp/instruments-probe
codesign -d --entitlements - /private/tmp/instruments-probe
```

Before the user's boot-policy change, AMFI rejected the binary before `main`.
On the current boot, SIP reports disabled and `boot-args` contains
`amfi_get_out_of_my_way=1`; the restricted-entitlement binary launches and
reaches recording. A valid direct CPU trace has been produced through the
signed carrier route described above.

One experimental local route described by the AMFIExemption project is disabling
SIP and booting with `amfi_get_out_of_my_way=1`. This reduces security for the
whole booted OS, and its behavior on this macOS release is unverified. Do it on
a separate test volume or VM if possible. Do not modify or re-sign Xcode's own
binaries. Restore by removing that boot argument and re-enabling SIP from
Recovery when the experiment is over.

Authenticated root / SSV need not be disabled for this path: the executable is
in `/private/tmp`, and the experiment does not change the sealed system volume.
TCC is a separate authorization system, but reports from AMFI-disabled systems
show that TCC prompts or permission changes can fail in that configuration.
Whether that happens on this Mac and OS build is untested. Do not rely on being
able to grant a missing permission after the AMFI change.

While AMFI is still enabled, settle on a stable launcher and grant any permissions
it actually requests. The probe made a `kTCCServiceListenEvent` (Input Monitoring)
preflight check, which `tccd` attributed to Codex; this was not an observed TCC
denial, and Input Monitoring has not been proven necessary for recording. If
continuing through Codex, resolve its current prompt now. If switching to
Terminal or a host app, establish that launch path and its needed TCC grants
before changing boot policy. `Developer Tools` may be relevant when the host
debugs other processes. Keep the target app's existing privacy grants in place.
Do not pregrant unrelated categories such as Full Disk Access or Screen Recording.

The restricted-entitlement probe cannot launch under the current policy, so it
cannot directly prompt for its own TCC grants yet. If its first successful launch
reveals a new TCC requirement and prompts/settings are broken with AMFI disabled,
a temporary boot with AMFI restored may be necessary to grant it. Keep its code
signature and install path stable across those boots so TCC can recognize it.

## Wrapper shape after the authorization experiment

Keep Objective-C declarations for the private classes in one small shim. Expose
Swift `TraceTemplate`, `TraceTarget`, `TracePlan`, and `RecordingSession` types.
`RecordingSession.start()` should await an actual recording-start callback (or
`isRunning` transition), `stop()` should end the command and wait for completion,
and `save()` should verify a run exists before returning the `.trace` URL. For
targeted app events, let a debug-only app trigger send a start/stop event to the
Mac host and wrap each phase with Points of Interest signposts. The host controls
the privileged recording process; the app does not link these frameworks.
