# Demonstration and feedback notes (draft)

This document is a draft for a future Apple Feedback report or public demo.
Nothing here has been submitted or published.

## Demonstration

1. Build the local source distribution with `build.sh`, then start the signed
   `xctrace` carrier with `run-host.sh`.
2. Launch a Mac Catalyst Debug build of Sort Symphony with
   `LOCAL_INSTRUMENTS_TRACING` and `SORT_SYMPHONY_TRACE=1`.
3. Select CPU Profiler, choose a sorting algorithm, and record it with the
   **Runs** picker. Click **Record another trace** without restarting the app.
   The history rows show the same PID and distinct trace URLs; **All traces**
   opens the full retained history.
4. Select CPU + Signposts, File Activity, Swift Concurrency, or Allocations and repeat. The
   host waits for a `READY` acknowledgement before the sort starts and stops
   when the app sends `STOP`. This brackets one algorithm invocation or a
   chosen sequence of invocations.
   CPU + Signposts enables the app subsystem before the operation starts; a
   control trace exported raw events, a completed interval, and CPU samples.
5. Show a Swift `TracePlan.build` recipe and its typed validation: duplicate
   instruments, macOS-only exclusions, missing settings groups, and two
   observed Windowed Mode conflicts fail before recording. Add
   `.captureLast(.disabled)` to make the two tested graphics-statistic pairs
   valid.
6. Show the completed 5,398-case `CompatibilityResults.jsonl` and generated
   macOS filter. Each
   survey case uses a disposable trace, removes its separate ktrace scratch
   file, and has a per-case disk cap.

The app does not link Instruments private frameworks. A local host does the
recording, and the app's trigger is compiled only into opt-in Mac Catalyst
Debug builds. The private recorder currently works through Apple's signed
`xctrace` carrier. The standalone ad hoc probe can reach DTServiceHub with
experimental entitlements on this machine but has not acquired the kernel
trace resources required for CPU profiling.

## Apple Feedback draft

**Title:** Provide a supported programmable API for short, targeted
Instruments recordings

Instruments is excellent for interactive investigation, but repeatedly
recording small app events requires a GUI loop or `xctrace` subprocesses.
`xctrace` does not expose a typed composition model or clear compatibility
errors before the run. It has a `--notify-tracing-started` Darwin notification,
but coordinating that with a subprocess and a stop signal remains awkward
for one app event. Its `--show-recording-options` command reports
instrument options but ignores an accompanying option file; a partial option
document fails during recording, and some warnings accompany otherwise
exportable traces. We have also observed a Processor Trace stop timeout in
the private recorder, while 100 ms CLI runs sometimes succeed.

A public Swift recording API could provide a template and instrument catalog,
typed options, target and recorder-mode capability checks, an async
start/stop/save lifecycle, explicit privacy requests, and a stable result
type with run issues and exported table metadata. It would let a debug build
request a trace for one operation while keeping the trace recorder outside
the app process. A system-provided authorization path would avoid relying on
private entitlements and signed-process injection.

### Reproducible evidence from this installation

- macOS 27.0, Xcode 27.0 (27A266a): Power Profiler requires iOS/iPadOS;
  RealityKit Trace requires visionOS. Five individual instrument IDs report
  explicit platform errors. The catalog stores exact messages.
- Adding CPU Counters without a counting mode fails preflight even when the
  parent template records successfully.
- Advanced Graphics Statistics fails with a Windowed Mode error when added
  to Audio System Trace or Game Performance. Both selected template archives
  store a five-second window limit; other tested parent templates accept it.
  A typed `Capture Last: disabled` setting made both combinations export.
- Processor Trace has intermittently timed out at stop and once reported a
  kperf lock conflict during retries. A CPU Profiler control trace succeeded
  afterward, and no leftover `xctrace` or fixture process was found.
- A long automated `xctrace` sweep accumulated roughly 350 GB of ktrace
  scratch storage. The root cause was `DTServiceHub` retaining 3,911 deleted
  ktrace files through open file descriptors, totaling 367.34 GiB. Sending
  that service TERM released the storage immediately. The harness now caps
  visible scratch, checks deleted-open ktrace storage after every case, and
  can restart only the retaining service. This is a separate candidate
  Feedback report about temporary-file lifecycle management.
- Foundation Models, Network, and HTTP Traffic can request privacy consent or
  capture sensitive content, so the automated compatibility harness skips
  them by default. No TCC denial has appeared in the current survey.

`PROFILE_INVARIANTS.md` identifies which findings come from the UI, archive,
CLI decoder, or a saved trace. All 5,398 generated finite-matrix cases are
classified in the checked-in result stream.

## Show HN draft

**Title:** Show HN: A typed Swift API for targeted Instruments traces

I wanted to profile individual sorting algorithms and app events without
repeatedly driving the Instruments UI or coordinating an `xctrace` subprocess.
This experiment wraps the private Xcode 27 Instruments frameworks in a typed
Swift API and runs them inside Apple's signed `xctrace` carrier.

The API builds trace plans with a Swift result builder, validates templates,
targets, instrument additions, option ranges, platform availability, and known
incompatible pairs before recording, and exposes synchronous, callback, and
Swift Concurrency entry points. A debug-only Mac Catalyst client waits for a
local host's `READY`, executes one named operation, emits an `OSSignposter`
interval, then sends `STOP`. Sort Symphony includes a profile picker, a repeat
count for very fast algorithms, and persistent links to multiple traces from
the same process.

I also built a resumable compatibility harness for the installed Xcode. It
classified 5,398 finite cases across templates, instrument additions, pairwise
combinations, and decoded options. Along the way it found platform exclusions,
two Windowed Mode conflicts, Processor Trace stop trouble, privacy prompts,
and a `DTServiceHub` temporary-file leak that retained 367 GiB of deleted
ktrace data. The final CPU + Signposts control recorded 4 raw signpost rows,
1 completed interval, and 4,354 CPU samples in one trace.

The source distribution contains no Apple frameworks or recorded traces. It
is intentionally tied to Xcode 27, relies on private APIs, and needs local
security policy changes or the signed carrier technique described in the
README. I would especially value feedback on the declarative API shape and on
use cases for a supported public recording API.

Suggested demo media: a short screen recording that selects CPU + Signposts,
runs the same algorithm twice, opens both history rows, then shows the completed
interval and CPU samples in Instruments. Link the repository, the invariants
document, and the Apple Feedback number after submission.

## Public demo boundaries

This is an Xcode-version-specific experiment, not a supported Instruments
SDK. The source package includes no copied Apple frameworks or recorded trace
bundles. Avoid presenting an exportable trace as proof that every instrument
produced useful rows for the chosen workload. The CPU-only survey fixture,
for example, triggers a “no SwiftUI data” warning in SwiftUI traces.
