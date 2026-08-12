# Sort Symphony as an Audio Unit — Implementation Plan

Status: **companion-mode bridge shipped.** This is the corrected, current architecture — a
substantial revision of the original plan, made after real Logic Pro testing on Mac revealed the
first four implementation phases had built the wrong product model (see the "Revision history"
callout below). See `ARCHITECTURE_V2.md`/`IMPLEMENTATION_PLAN.md` for the existing app's shipped
design this plan builds alongside.

**Revision history, briefly:** Phases 1-4 (still described in git history and in this document's
older diffs) built a self-contained AU that ran its own independent copy of a sort/shuffle inside
the extension process, with no connection to the standalone app — reasoning that Logic must own the
plug-in's entire lifetime and can't assume the app is running. Loading that build in real Logic Pro
surfaced the actual intent: the AU should be a **live send from the running standalone app**,
replacing local speaker output with Logic Pro routing while connected — not an independent
generator. That correction, plus a related realization that iPadOS's aggressive background-app
termination makes a persistent live pipe structurally unsound there, produced this revision. The
headless, self-contained driver was deleted; the platform scope narrowed to Mac Catalyst only,
permanently.

**What this document now commits to:**

1. **AUv3 is the only plug-in format shipped or planned** — VST3/AAX remain described-but-deferred
   compatibility ideas (§9-10), unchanged in that regard from the original plan.
2. **The AU is a companion-mode relay, not a self-contained generator.** It has no sort/shuffle
   logic of its own; it exists only to receive and re-render events the *running* standalone app
   produces. With the app not running or not reachable, the AU is simply silent — there is no
   fallback mode.
3. **A Unix domain socket bound inside a shared App Group container is the shipped IPC
   mechanism** — confirmed via Apple DTS forum guidance as the supported, sandbox-compatible way
   for the standalone app and an AU extension instance hosted by an unrelated third-party host
   (Logic Pro) to talk directly. Raw XPC (a custom Mach service) is **not** used for this — setting
   up a custom XPC listener reachable from inside a third-party host's sandboxed extension process
   is not the pattern Apple designed AUv3 around.
4. **This IPC is never part of the realtime audio-render path.** `internalRenderBlock` only ever
   calls `ToneRenderer.render(...)`; the bridge client runs entirely off the render thread and only
   ever enqueues into the same lock-free command queue the standalone app's own render path uses.
5. **Platform scope is Mac Catalyst only, permanently** — not deferred pending iPadOS Logic Pro
   access. iPadOS's aggressive background-app termination under memory pressure could silently sever
   a persistent pipe at arbitrary times with no recourse; macOS does not jetsam-kill background apps
   the same way, so this architecture is structurally sound on Mac and structurally unsound on
   iPadOS regardless of testing access. If this is ever revisited, the underlying App Group +
   same-device IPC mechanism would transfer, but there is no iPadOS variant planned.
6. **The App Group entitlement ships now**, on both the app and the extension — it is load-bearing
   for v1, not a reserved-but-unused capability.
7. **VST3 is optional future compatibility, delivered outside the Mac App Store** via a separately
   distributed, Developer ID-signed bridge — not a phase in the committed roadmap. Unchanged from
   the original plan, except that the underlying event-transport mechanism such a bridge would reuse
   now already exists and ships (§8), rather than being a reserved-but-unbuilt spike.
8. **AAX is a still-more-conditional future target**, gated on real licensing/tooling cost, using
   the same bridge/core if it's ever pursued.
9. **A minimal, audio-production-only parameter UI** for the AU is planned as a near-term follow-on
   (§7's "Plug-in UI" subsection) — explicitly not a reimplementation of the app's own sort
   visualization, algorithm details, or code display inside the plug-in host.

---

## 1. The product model: a live companion-mode relay (AUv3, shipped)

The goal is to route the *running* standalone Sort Symphony app's own live audio into a DAW —
something you drop on a Logic Pro track, then run a sort with sound on in the standalone app, and
hear that same audio arrive on the track, ready for Logic's effects chain on top **instead of** the
app's own local speaker output. This intentionally avoids building any effects/node-editor system
inside Sort Symphony itself — Logic Pro already is one.

```text
Sort Symphony (running, standalone app)
    ↓ SortAudioCore / ToneKitDSP (local DSP, unchanged)
    ↓
AudioService                         (routes: bridge if connected, else local speakers)
    ↓ SortAudioBridgeServer          (Unix domain socket, shared App Group container)
    ↓
SortAudioBridgeClient                (inside the AU extension process)
    ↓ SortAudioCore.LocalToneEventSink → ToneKitDSP.ToneRenderer
    ↓
AUv3 (internalRenderBlock)
    ↓
Logic Pro (Mac) — the extension's audio output on its track
```

for **macOS, through the existing Mac Catalyst product, only.** This is the entire committed scope.
VST3 and AAX are addressed in §9-10 as deferred, conditional compatibility work.

Explicitly **not** in scope:

- No self-contained/headless mode — the AU never runs a sort or shuffle of its own, on any platform.
  There is deliberately no fallback path for "the app isn't running": the AU is simply silent then,
  matching "there's no control, and it doesn't load as-is, so it's easier to just make companion mode
  the default."
- No iPadOS AU target, now or planned — permanent, not deferred (see the revision-history callout
  above for the reasoning).
- No bounced/pre-rendered audio file.
- No requirement that the DAW supply MIDI notes as the source of truth for pitch/timing.
- No incoming audio signal that Sort Symphony transforms (`ToneKitDSP` has no audio-input processing
  path today, and this plan doesn't add one).
- No rewriting of individual sorting algorithms around AU/VST/MIDI/DAW-transport concepts. Every
  algorithm in `BuiltInAlgorithms` stays exactly what it is today: a pure, synchronous producer of
  `SortOperation`s against `RecordingEngine`, with zero awareness that a plug-in host might ever
  consume its output, directly or indirectly.
- No DAW-hosted UI beyond the minimal, audio-production-only parameter view planned in §7 — no
  visualization, algorithm detail, or code display ever renders inside the AU host.

**Component type: what Logic actually needs to see.** Registered as an instrument (`aumu`), matching
a real, working precedent for this exact product shape: Wotja (Intermorphic) ships as an AUv3 hosted
successfully in Logic Pro that generates its own audio from an internal engine, with MIDI as
optional/secondary control rather than the source of truth. Sort Symphony's AU follows the same
shape, except its "internal engine" is a relayed feed from the running standalone app rather than a
self-driving generator. Incoming MIDI is never load-bearing.

---

## 2. Preserve the existing sort → sound semantics; extract, don't bypass

`AudioService` (`Modules/AudioEngineKit/Sources/AudioService.swift`) is `@MainActor`, reads
`AppSettings.synthNoteRange` (`Modules/SettingsKit/Sources/AppSettings.swift:52`), and can't run
directly on an AU realtime render thread — but the pitch/timing semantics it embodies today are
exactly what should carry over unchanged, so the plug-in sounds like Sort Symphony rather than a
reskinned synth.

`SortSession.startReplay` (`Modules/SortFeature/Sources/SortSession.swift:471-474`) already supplies
the right semantic unit — `audio.play(value: replay.frame[i].value, in: range, holdSeconds:
holdSeconds)` — and `AudioService.frequency(forValue:in:noteRange:)`
(`Modules/AudioEngineKit/Sources/AudioService.swift:120-128`) is already a pure, `nonisolated`,
side-effect-free function with no `@MainActor` dependency at all — it's `AudioService`'s *state*
(the live `Oscillator`/`AmplitudeEnvelope` graph, `AppSettings` access) that's MainActor-bound, not
this specific logic.

**Extraction: `SortAudioCore`**, a new non-UI, non-`MainActor` module:

```text
Sort/replay
    ↓
SortToneEvent            (value, range, holdSeconds — same shape play() already receives)
    ↓
ToneMapper                (today's AudioService.frequency(forValue:in:noteRange:) + the
    ↓                      gate-retrigger-only-on-pitch-change rule from AudioService.play)
ToneCommand                (frequency + gate open/close, ready for ToneKitDSP)
```

Both the standalone app (`AudioService`, refactored to sit on top of `SortAudioCore` +
`ToneKitAVFoundation`) and the AU consume the same `ToneMapper`, so a pitch or gate-retrigger tweak
made once is heard identically everywhere.

`SortAudioCore` does **not** own an independent driver that picks and runs an algorithm/shuffle on
its own — an earlier revision of this plan built exactly that (reasoning that a plug-in instance has
no `SortSession`/UI feeding it choices, so it must be self-sufficient the moment Logic instantiates
it), and real testing showed that isn't the wanted product: the AU has no sort logic of its own on
any platform. It only ever relays `SortToneEvent`s that arrive over the companion-mode bridge (§8)
into its own `ToneRenderer`, via the same `LocalToneEventSink` the standalone app itself uses.

`SortAudioCore` is also where the transport-neutral event boundary lives — see §4.

---

## 3. ToneKit must split: DSP core vs. AVFoundation adapter

`Oscillator.fill(_:sampleRate:)` (`Modules/ToneKit/Sources/Oscillator.swift:102`) is already close
to a reusable, host-independent DSP primitive — caller-owned storage, a sample rate, no `AVAudioNode`
involved directly.

`AmplitudeEnvelope` (`Modules/ToneKit/Sources/AmplitudeEnvelope.swift`) doesn't separate cleanly
today: it **owns the `AVAudioSourceNode`**, and the envelope's per-sample gain-update loop
(`Self.nextGain`, already a pure static function at line 153) runs *inside* that node's render
closure (lines 100-123), reading/writing a `Mutex<State>`-boxed (`StateBox`, lines 63-70)
phase/gain/gate state on every sample. `Node.swift`'s `Node`/`AudioEngine` types are genuinely
AVFoundation-specific (`avAudioNode: AVAudioNode`) and stay that way.

**Target split:**

```text
ToneKitDSP/                         (NEW — host-independent, no AVFoundation import)
    OscillatorDSP                   phase/frequency state + fill(), lifted from Oscillator
    EnvelopeDSP                     phase/gain state + nextGain() math, lifted from AmplitudeEnvelope
    ToneRenderer                    owns OscillatorDSP+EnvelopeDSP exclusively, drains due
                                     ToneCommands, renders a caller-owned buffer (§4-5)
    ToneCommand / ToneEvent         frequency + gate open/close (+ optional sample offset, §5)

ToneKitAVFoundation/                (NEW — what today's ToneKit's AVFoundation half becomes)
    Node, AudioEngine               unchanged from today's Node.swift
    AVAudioSourceNode adapter       render closure now just calls ToneRenderer.render(...) —
                                     no envelope math or Mutex left in this file at all
```

`Modules/ToneKit/` is retired as a single module once this split lands. **Do not build an
`AVAudioEngine` graph inside the AU merely to pull audio out of ToneKit** — `SortAudioUnitKit`'s
`AUAudioUnit.internalRenderBlock` calls `ToneRenderer.render(...)` directly, the same entry point
`ToneKitAVFoundation`'s `AVAudioSourceNode` closure calls for the standalone app. One DSP core, thin
adapters per host — no adapter contains DSP logic of its own. This same shape is what makes a later
VST3/AAX adapter (§9-10) additive rather than a fork.

---

## 4. A transport-neutral event boundary — now genuinely exercised by two transports

`SortAudioCore` produces a canonical logical event representation (`SortToneEvent`) that doesn't
care whether the consumer is in-process or across the companion-mode bridge. Designing this
boundary in early (rather than retrofitting it after the AU shipped) turned out to matter for
exactly the reason originally anticipated, just via a different transport than first assumed:

```text
SortToneEvent
    │
    ├── LocalToneEventSink → realtime SPSC queue → ToneRenderer      (standalone app, no bridge
    │                                                                  connected; AU extension,
    │                                                                  fed by the bridge client)
    │
    └── SortAudioBridgeServer.broadcast(_:noteRange:)                 (standalone app, when a
            ↓                                                         bridge client is connected)
        Unix domain socket, shared App Group container
            ↓
        SortAudioBridgeClient (inside the AU extension process)
            ↓
        LocalToneEventSink → realtime SPSC queue → ToneRenderer
```

Shape actually shipped:

```text
protocol SortAudioEventSink: Sendable { func send(_ event: SortToneEvent, noteRange: ClosedRange<Int>) }

final class LocalToneEventSink: SortAudioEventSink {
    // wraps the bounded command queue feeding a ToneRenderer directly, in-process — used by both
    // the standalone app (when nothing's connected) and the AU extension (fed by the bridge client)
}
```

**The rule this exists to enforce: sort code and tone-mapping code must never know or care where
events ultimately go.** `ToneMapper`/`LocalToneEventSink` don't know whether their caller is
`AudioService` playing locally or a `SortAudioBridgeClient` relaying a received message — the
`SortAudioBridgeKit` module (§8) sits entirely to the side of this boundary, moving *events* over
its own wire format, never touching `ToneKitDSP` or `SortAudioCore`'s types beyond consuming
`SortToneEvent` and calling a `SortAudioEventSink`.

---

## 5. Realtime safety is an architectural requirement, not a profiling follow-up

Revise around **single ownership of DSP state by the render thread**, replacing `Oscillator`'s
current render-thread `Mutex`:

```text
sort/replay/control side (SortAudioCore, off the render thread)
        │
        │ ToneCommand / ToneEvent, via LocalToneEventSink
        ▼
bounded, lock-free (SPSC) queue
════════════════════════════════════ realtime boundary
        ▼
ToneRenderer                          (render thread only, past this point)
├── oscillator state (OscillatorDSP)      — owned exclusively here, no Mutex
├── envelope state (EnvelopeDSP)          — owned exclusively here, no Mutex
├── phase
└── render scratch storage                — preallocated, sized to the host's max frame count
```

Explicit, non-negotiable requirements for `ToneRenderer.render(...)` and everything it calls:

- No locks (a lock-free SPSC queue's atomic operations are the one designed-in exception).
- No heap allocation.
- No `MainActor` (or any actor) isolation.
- No UI/framework dependencies (`ToneKitDSP` never imports `AVFoundation`, `UIKit`, or `AppKit`).
- Caller-owned output buffers; sample rate and frame count supplied per call, never cached.
- Bounded work per call, proportional only to frame count.
- **No IPC of any kind** — no XPC call, no cross-process wait, no filesystem access, no allocation
  of an IPC message, no cross-process lock. This is a hard rule, not just an implication of "no
  locks": it applies equally to a hypothetical future VST3/AAX `process()` callback if a bridge ever
  exists (§8-9) — the render thread never talks to the bridge, ever, under any circumstance. If the
  bridge or the standalone app disappears or falls behind, rendering continues with whatever
  state/events are already available locally.

`Oscillator`'s current scratch-array approach needs the same treatment: `ToneRenderer` preallocates
render scratch storage during a preparation/allocation phase sized to the host's advertised maximum
render block size (`AUAudioUnit.maximumFramesToRender`), rather than resizing a Swift array inside a
render callback.

---

## 6. Push-based sort events behind a pull-based DAW renderer

The app today is push-shaped (*an operation occurred → make this sound for this duration*); a DAW is
pull-shaped (*render the next N audio frames, now, synchronously*). Sorting algorithms must not be
rewritten to understand the pull side — that impedance-matching lives entirely inside `LocalEventSink`
→ `ToneRenderer`.

Whether commands need a **sample-accurate offset within the block** or block-boundary granularity is
acceptable is worth deciding empirically once real render-block sizes are in play — recommend
including an optional offset field in `ToneCommand` from the start rather than retrofitting it later,
since it costs little to add now and would require touching every consumer to add afterward.

This same queue/`ToneRenderer` pair serves every render context identically:

```text
Standalone app:  ToneKitAVFoundation's AVAudioSourceNode render closure → ToneRenderer.render()
AUv3:            SortAudioUnitKit's AUAudioUnit.internalRenderBlock     → ToneRenderer.render()
(deferred) VST3: native macOS adapter's process()                      → ToneRenderer.render()
```

---

## 7. Mac Catalyst only, permanently: the AUv3 target itself

### Why not iPadOS

An earlier revision of this plan targeted both iPadOS and macOS, on the reasoning that the AU was
self-contained and platform-agnostic. Once the product model became companion mode — a persistent
live connection to a *running* standalone app instance — iPadOS stopped being a good fit
structurally, independent of testing access: iPadOS aggressively terminates backgrounded apps under
memory pressure, with no recourse, which would silently sever a persistent pipe at arbitrary times.
macOS does not jetsam-kill background apps the same way, so a persistent live connection is
architecturally sound there and not on iPadOS. This is a **permanent** scope decision, not a
temporary deferral pending a Logic Pro for iPad subscription (which doesn't exist anyway) — see the
top-of-document revision-history callout.

### macOS / Mac Catalyst — packaging, confirmed working

This project is Mac Catalyst end to end — no native macOS (AppKit or macOS-native SwiftUI) target
exists anywhere in the repository, and none is needed: a normal Catalyst-built AUv3 extension,
embedded in the existing Catalyst app, builds, embeds (`Contents/PlugIns/AUv3Extension.appex`),
signs, and registers cleanly on the current Xcode 26 toolchain. Two small, expected fixes were
needed getting there — `SortAudioUnit.swift` needed an explicit `import CoreAudio` for
`UnsafeMutableAudioBufferListPointer` on Catalyst specifically (the same gotcha `ToneVoice.swift`
already hit earlier in this project), and the app's dependency on the extension needs a
`condition: .when([.catalyst])` platform filter (Tuist doesn't infer this from the extension
target's own `destinations`).

Real, OS-level registration is confirmed: `auval -a` lists the component (`aumu SrtS NkHb - Nick
Hubbard: Sort Symphony`), and `log show` during a validation attempt shows the extension process
actually launching through the real PlugInKit/RunningBoard/XPC machinery and logging "plugin loaded
and ready for host." `auval -v aumu SrtS NkHb` (with or without `-oop`) doesn't complete a full pass
— it hits `FATAL ERROR: OpenAComponent: result: -10863` (`kAudioUnitErr_CannotDoInCurrentContext`)
roughly 30 seconds after the extension process itself successfully reports ready, consistent with
`auvaltool`'s own instantiation path still routing through the legacy synchronous
`AudioComponentInstanceNew`/`OpenAComponent` API rather than the modern async
`AVAudioUnit.instantiate(with:options:completionHandler:)` path a real host uses — a known category
of `auval` limitation with pure-v3, extension-hosted components, not evidence the AU itself is
broken for a real host. Real Logic Pro on Mac (a perpetual license, unlike the iPad subscription
this project never had) is what actually resolves this ambiguity — see §14's phase table.

### Companion-mode connection lifecycle

```text
Standalone app launches → AudioService.start() binds SortAudioBridgeServer's Unix socket
                           (inside the shared App Group container; no-op if unreachable)
Logic loads the AU on a track → SortAudioUnit.allocateRenderResources() starts a
                                 SortAudioBridgeClient, which connects out and retries on a short
                                 interval until the server is reachable
Sort runs with sound on in the app → AudioService.play(...) broadcasts to the bridge instead of
                                      playing locally (replaces, never adds to, local output)
App quits / AU is removed from the track → the corresponding connection fails/cancels; the other
                                            side simply goes back to "nothing connected" — the
                                            standalone app resumes local playback, the AU goes silent
```

Order independence is deliberate: Logic may instantiate the AU before or after the app is running,
in either order, and either side may restart independently — the bridge client's reconnect loop and
the "no clients connected → play locally" fallback in `AudioService` both exist specifically so
neither side has to assume anything about the other's lifecycle.

### Plug-in UI: the remote (shipped)

A custom `AUViewController`-hosted SwiftUI view (`SortAudioUnitViewController`/
`SortAudioUnitParameterView.swift`, hosted via `UIHostingController`), with two sections — nothing
else, no sort visualization, algorithm detail, or code display anywhere in it:

- **Transport**: the same sort-transport actions already available from the app's own run-control
  bar and menu commands (`RunControlBar.swift`, `App/Sources/SortCommands.swift`) — play/pause,
  restart (seek to start), regenerate (fresh shuffle, restart from scratch), step forward/back, sound
  toggle. Fire-and-forget buttons, no state readback from the app (the buttons work like a keyboard
  shortcut with no visual confirmation beyond what you hear) — deliberately excludes algorithm/
  visualizer/size pickers, Export Tape, and the Automations menu, since those either expose
  "algorithm details" or aren't audio-relevant.
- **Tone**: `AUParameterTree`-backed sliders for the audio-production-relevant DSP controls
  `ToneKitDSP` already models — Attack/Decay/Sustain/Release, Detune (±50 Hz), Gain.

**New reverse-direction channel**: the transport buttons need to reach the *running* app, the
opposite direction from `SortToneEvent`. `SortAudioBridgeKit`'s wire format grew a 1-byte channel
tag (`BridgeEnvelope`) so both directions fit the same fixed-size framing — channel 1 is the existing
`SortToneEvent` payload, channel 2 is a `RemoteControlCommand` (a `UInt8` enum:
`togglePlayback`/`restart`/`regenerate`/`stepForward`/`stepBackward`/`toggleSound`, defined in
`SortAudioCore` alongside `SortToneEvent`). The server (app side) gained its first receive loop —
previously write-only — and the client (extension side) gained `sendRemoteControlCommand(_:)`.
Dispatch from a received command to an actual `SortSession` call happens in `App/Sources/
Sort2App.swift`, set once at launch: `AudioEngineKit` can't import `SortFeature` (the dependency runs
the other way), so the mapping from `RemoteControlCommand` to `SortCoordinator.shared
.activeSortSession?...` calls lives at the app-composition-root level, mirroring
`SortCommands.swift`'s existing menu-command dispatch exactly.

Tone parameter changes reuse the exact realtime-safety mechanism §5 already established: an
`AUParameter`'s `implementorValueObserver` enqueues a `ToneCommand` (six new cases —
`setAttackDuration`/`setDecayDuration`/`setSustainLevel`/`setReleaseDuration`/`setDetuningOffset`/
`setAmplitude`) into the same lock-free `ToneCommandQueue` `setFrequency`/gate commands already use;
`implementorValueProvider` reads a `Mutex`-protected snapshot on `SortAudioUnit`, since
`OscillatorDSP`/`EnvelopeDSP` are owned exclusively by the render thread and can't be read directly.

### Known gotchas (found via real Logic Pro testing)

- **The principal class must be a real `AUViewController`, not a bare `NSObject`, even before any
  UI is built.** The original `SortAudioUnitFactory` was a plain `NSObject` conforming only to
  `AUAudioUnitFactory` — the extension registered fine (`auval -a`, `pluginkit` both recognized it)
  and the process launched cleanly, but Logic would load it, sit idle for several minutes, then
  silently tear the connection down — `allocateRenderResources()` was *never called*, so
  `SortAudioBridgeClient` never even attempted to connect. The system log showed why, right at
  launch: `[PlugInKit:subsystems] Bootstrapping; misconfigured plugin; external subsystem
  [NSViewService_PKSubsystem] not present; possible missing linkage`. Every real Apple AUv3 template
  pairs `com.apple.AudioUnit-UI` with an `AUViewController`-conforming principal class, even for a
  plug-in with no custom UI at all — a bare `NSObject` doesn't provide the view-vending/ViewBridge
  linkage that extension point's host-side machinery expects. Fixed by replacing
  `SortAudioUnitFactory` with `SortAudioUnitViewController: AUViewController, AUAudioUnitFactory`
  (no storyboard needed — `NSExtensionPrincipalClass` pointing directly at an `AUViewController`
  subclass is Apple's own documented, supported pattern). If a future AU-hosted extension registers
  successfully but the host never proceeds past load, check for this exact signature via `log show
  --predicate 'process == "<ExtensionName>"'` across the extension's full launch-to-teardown window
  (several minutes) before assuming it's an `auval`-only tooling quirk.
- **Sound must be on in the app for the bridge to carry anything.** `AppSettings.soundEnabled` is
  checked in `SortSession.makeOnStepClosure` *before* `audio.play(...)` is ever called —
  `AudioService.play()` itself has no sound-enabled check. The gate is upstream of both local
  playback and the bridge broadcast, in the exact same code path — turning sound off in the app
  silences Logic too, not just the speakers. There's no way to route silently-generated events to
  the bridge only; if you want to hear nothing locally but still feed Logic, that's a real gap this
  architecture doesn't yet address (companion mode as designed = "sound is either fully off, or
  going to exactly one destination").
- **Logic's Record button captures MIDI, not audio, for Software Instrument tracks.** Since this AU
  never receives or reacts to MIDI at all, hitting Record produces an empty region — there's no
  performance to capture. Worse, "Bounce in Place" (the usual offline workaround) doesn't work
  either, because it renders offline, decoupled from real time, but this AU's audio only exists
  because the standalone app is enqueuing it in actual wall-clock time as a sort runs — there's
  nothing to bounce ahead of time. The correct capture method: route the instrument track's **output
  to a bus**, create a **new audio track** with that bus as input, record-enable the audio track, and
  hit Record while a sort is actually running in the standalone app. **Confirmed live: do not mute
  the instrument track.** The obvious-seeming "mute it to avoid a doubled signal" step is actually
  wrong for this exact routing — muting the track that the bus routing depends on silences the signal
  reaching the bus too, not just the track's own direct output, so the recording goes silent as well.
  Leaving the instrument track unmuted works correctly and doesn't double anything, since its output
  is already redirected entirely to the bus rather than also feeding the main mix.
- **A stuck local note during the local-to-bridge handoff was a real bug, now fixed.** Before the
  fix, a note already ringing locally (enqueued before an AU instance connected) kept playing until
  whatever `holdSeconds` was already in flight expired on its own, since `play()`'s routing only
  affects *new* notes. `AudioService` now enqueues an immediate `.closeGate` on its local `renderer`
  the moment `onConnectedClientsChanged` reports a new connection, guaranteeing local speakers go
  silent right away rather than after a variable tail. Confirmed live: Logic correctly receives audio
  and mutes itself appropriately when the standalone app isn't actively playing back.
- **The bridge is off by default, with its own priming UI, because the system's own prompt can't be
  customized.** The first time the bridge actually connects, macOS shows a "would like to access data
  from other apps" prompt — this is a fixed TCC dialog with no Info.plist usage-description key
  (unlike Camera/Microphone), so its wording can't be changed. Rather than a user hitting that vague
  prompt unprompted the first time they happen to play a sort with sound on,
  `AppSettings.audioUnitBridgeEnabled` defaults to `false`, and Settings shows explanatory text
  (visible only while the toggle is on) describing what the upcoming system prompt means and why it's
  safe to allow. Turning the toggle on immediately calls `AudioService.setAudioUnitBridgeEnabled(true)`,
  which binds the bridge's socket right away — independent of whether a sort has ever played sound —
  so the system prompt (and our own explanation) both appear at the moment of clearest intent, not
  buried inside an unrelated action.

---

## 8. The companion-mode bridge (shipped): App Group + Unix domain socket, not XPC

This is now the core mechanism the whole product depends on, not a reserved future option. Research
against Apple's own guidance (Apple DTS forum posts, not just community folklore) for the specific
scenario here — a standalone app reaching into an extension instance a **third-party host** (Logic
Pro) instantiated, not a container app talking to its own embedded extension in the usual sense —
found:

- **Raw XPC (`xpc_connection_create_mach_service`, a custom Mach service name) is not the supported
  pattern here.** Setting up a custom XPC listener reachable from inside a third-party host's
  sandboxed extension process is non-trivial and not the standard pattern Apple designed AUv3
  around.
- **A Unix domain socket bound inside a shared App Group container is the documented, supported,
  sandbox-compatible mechanism** for exactly this: two sandboxed processes communicating, as long as
  both declare the same App Group entitlement and the listening socket's path lives inside
  `containerURL(forSecurityApplicationGroupIdentifier:)`.
- Darwin notifications (`CFNotificationCenterGetDarwinNotifyCenter`) are a standard complement for
  lightweight signaling, but aren't needed here — a live socket connection's own existence already
  tells both sides "is anything currently listening/connected," so there's no separate wake-up signal
  to build.

**Design, as shipped in `Modules/SortAudioBridgeKit/`:** the standalone app is the **server**
(`SortAudioBridgeServer`, one socket path inside the shared App Group container); the AU extension is
the **client** (`SortAudioBridgeClient`, connects out, retries on a short interval while
disconnected). This naturally supports multiple simultaneous AU instances (e.g. one per Logic track)
as multiple fanned-out client connections from one server, with no extra design work.

```text
Sort Symphony.app (server)
        │
        │ Unix domain socket, path inside the shared App Group container
        │ (NWListener/NWConnection, Network.framework)
        ▼
AUv3Extension process (client) — one connection per loaded instance
```

Transport: `Network.framework`'s `NWListener`/`NWConnection` with `NWEndpoint.unix(path:)` — a
modern, async-friendly, standard-framework API for Unix-domain-socket IPC, avoiding hand-rolled BSD
socket code. `sockaddr_un.sun_path`'s 104-byte limit on Darwin is a real, hit-in-practice constraint
for App-Group-container-derived paths (`SortAudioBridgePath` keeps the filename to a few characters
and refuses to hand back a path over a conservative safety threshold, rather than letting `bind()`
fail with an opaque error).

**Wire format:** a small, fixed-size, versioned binary struct (`BridgeWireCodec`) — a version byte
plus `SortToneEvent`'s three fields and the `noteRange` bounds, all fixed-width integers/bit
patterns, no JSON/Codable. Because every field is fixed-width, the encoded size never varies, so no
length-prefix framing is needed: a reader just always reads exactly `encodedByteCount` bytes per
message. Big-endian throughout, independent of either end's native endianness.

**Hard rule, restated from §5 in this specific context:** the render thread never talks to the
bridge. `internalRenderBlock` only ever calls `ToneRenderer.render(...)`; `SortAudioBridgeClient`
runs its own dispatch queue entirely off the render thread and only ever calls
`LocalToneEventSink.send(_:noteRange:)`, which itself only enqueues into the existing lock-free
command queue — the same path the standalone app's own render code drains. If the bridge connection
drops mid-render, rendering continues with whatever state/events are already enqueued; nothing in
the render path blocks on or waits for the bridge.

```text
Sort Symphony.app
    │
    │ SortToneEvent + noteRange, BridgeWireCodec-encoded
    ▼
Unix domain socket (App Group container)
    │
    ▼
SortAudioBridgeClient (AU extension process)
    │
    ▼
LocalToneEventSink → bounded command queue
════════════════════════════ realtime boundary
    ▼
ToneRenderer
    ↓
DAW audio buffer
```

### Wire-protocol properties, as shipped

- Explicitly versioned (a leading version byte; unknown versions are rejected, not misparsed).
- Based on semantic `SortToneEvent` concepts, not PCM — the bridge moves *events*, not audio.
- Independent of Swift object identity or pointers, and independent of AU/VST/AAX SDK types — a
  plain fixed-width byte encoding, not `NSSecureCoding` classes tied to one transport.
- Reconnects cleanly after either side restarts (`SortAudioBridgeClient`'s retry loop;
  `SortAudioBridgeServer.hasConnectedClients` reflects live connection state, not a cached
  assumption).
- Multiple concurrent client connections (one per AU instance) are handled for free by the
  server's own connection map — no explicit session/stream identifier was needed for this.
- Not yet built: explicit backpressure/drop-behavior handling if a client falls behind (currently:
  `NWConnection.send` with `.idempotent` completion, no explicit queue-depth cap on the bridge side
  itself — the realtime-safe bounded queue on the *receiving* end, inside `ToneKitDSP`, is what
  actually bounds unbounded growth).

### Verified end to end

`SortAudioBridgeKit`'s own tests run a real server and client over a Unix socket in `/tmp` (standing
in for the App Group container — no real entitlement needed at this level) and confirm a broadcast
event round-trips correctly. `SortAudioUnitKitTests` goes one level up: constructs a real
`SortAudioBridgeServer`, points a `SortAudioUnit` at it via a test-only socket-path override, and
confirms the unit renders silent with nothing connected and non-silent once an event is broadcast.
Full Mac Catalyst app + extension builds succeed with the real App Group entitlement and code
signing. The remaining verification step is the one only a human can do: load the AU on a real Logic
Pro track and confirm the app's local speakers go quiet once connected, matching the "instead of"
routing this entire design exists to deliver.

---

## 9. Deferred Compatibility: VST3

Logic Pro never loads VST3 — the reason to want it at all is other DAWs on macOS (Ableton, Cubase,
REAPER, Bitwig, etc.). **VST3 is not a committed phase.** It's a described-but-deferred compatibility
target, conditional on the engineering/distribution cost being worthwhile once AUv3 has shipped.

The core stays exactly what §1-6 already builds:

```text
ToneKitDSP
SortAudioCore
canonical event protocol (§4)
```

**Note on naming:** a hypothetical VST3 effort's "DAW Bridge" would be a *different* component from
`SortAudioBridgeKit` (§8) — §8's bridge connects the standalone app to its own AUv3 extension inside
the same App Group; a VST3 bridge would instead be a separately distributed, Developer-ID-signed
helper process feeding externally distributed plug-in code, since the Mac App Store build can never
install that code itself (§11's guideline citations). They could plausibly reuse the *same* Unix
domain socket + App Group mechanism and even the same wire codec §8 already built and shipped —
that's a real head start this revision creates that didn't exist when VST3 was purely speculative —
but the second boundary (bridge → externally-hosted VST3 binary, running inside a host process Apple
doesn't govern the same way) is untested and shouldn't be assumed to work identically.

A future VST3 effort would *add*, without touching the core:

```text
Developer-ID DAW Bridge (new component, VST3-specific)
        +
native macOS VST3 adapter
        +
bridge-to-plugin event transport (untested — see the naming note above)
```

and reuse `ToneRenderer` exactly as the AUv3 adapter does.

**Distribution**: per §9's own architecture (see the shared distribution section, §11), VST3 is
delivered via direct, Developer ID-signed distribution from the Sort Symphony website — not
installed by the Mac App Store build, and not requiring a second Mac App Store listing.

**At the start of that work** (not now), spike, in this order:

1. Steinberg SDK/Tuist target integration.
2. Swift/C++ interoperability versus a narrow C ABI.
3. VST3 installation/notarization.
4. Bridge → VST3 communication in representative hosts.
5. Ableton Live/REAPER/Cubase/Bitwig compatibility as appropriate.

**Do not choose Swift/C++ interop now.** The second draft recommended it as a default; this draft
retracts that. A narrow C ABI (`@_cdecl`-exposed entry points wrapping `ToneRenderer`) may turn out
substantially easier to keep stable across Tuist/Xcode/plugin-toolchain version boundaries than
Swift/C++ interop, which is newer and less proven in a plugin-SDK context specifically. Treat the
choice as an empirical decision made when this phase actually starts, with both options evaluated
against the real toolchain versions in play at that time — not decided speculatively now.

Steinberg open-sourced the VST3 SDK under the MIT license in October 2025 (VST SDK 3.8), removing
the historical licensing friction; it also ships first-party AU wrapper code, but that direction only
helps going the other way (VST3 → AU), not for wrapping this project's Swift/AVFoundation core as
VST3 for free — the adapter above is still new, real engineering when it happens.

---

## 10. Deferred Compatibility: AAX

**Architectural goal only:** nothing in `SortAudioCore`, `ToneKitDSP`, or the event wire protocol
should assume VST3-specific semantics in a way that would preclude a future AAX adapter reusing the
same core and (if built) the same VST3-era bridge. **AAX is not in the implementation schedule.** It is
categorized as:

```text
architecturally possible
+
business/tooling feasibility TBD
```

not a promised target — and it's more conditional than VST3, not equally weighted.

Findings from Avid's own AAX SDK developer page (`developer.avid.com/aax/`), current as of this
draft:

- **SDK access**: gated behind a click-through license agreement; accepted developers are routed to
  an evaluation-toolkit download via `my.avid.com`.
- **iLok requirement, development**: "an iLok account is required to run Pro Tools for AAX testing"
  — a free iLok.com account is sufficient for the unsigned developer/evaluation path.
- **iLok requirement, commercial**: "commercial AAX development also requires an iLok USB key as
  part of the AAX digital signing process" — a physical hardware dongle, not just an account.
- **Commercial licensing/cost**: not disclosed on the public SDK page at all; developers are
  directed to contact `audiosdk@avid.com` directly "for information about how to obtain the
  necessary tools and license." No public pricing exists to cite.
- **Code-signing partner**: Avid's own SDK page does not name a signing vendor or process beyond "the
  AAX digital signing process" tied to iLok. Third-party developer accounts (forum reports, not
  Avid's own documentation) consistently describe Avid routing commercial signing through PACE (the
  iLok company) via a toolkit called Eden, with annual account/certificate renewal — this is included
  here as widely-corroborated secondary-source context, not as a first-party-confirmed requirement,
  since Avid's own page doesn't state it.

**Whether the generator/instrument model maps cleanly to AAX** is unresearched beyond the above and
should be the first thing evaluated if this work is ever picked up, alongside the real all-in cost
(iLok hardware, any annual signing fees, the undisclosed commercial license terms) against the actual
market case for Pro Tools support specifically, before any adapter work starts.

**Do not build a universal plug-in abstraction merely to accommodate this possibility.** AU/VST3/AAX
adapters may all remain thin, format-specific layers over the same `ToneRenderer`/`SortAudioCore` —
the neutrality goal (§4) is about the *event/DSP core*, not about pre-building a speculative
one-size-fits-all host-adapter framework.

---

## 11. Distribution architecture

```text
Shipped product:

Apple App Store
    ↓
Sort Symphony
    ├── Mac Catalyst app (with the AUv3 companion-mode bridge, §8)
    └── embedded AUv3 extension (Mac Catalyst only — no iPadOS variant)

Possible future external compatibility package (deferred, conditional):

Sort Symphony website / direct distribution
    ↓
Developer-ID signed + notarized Mac package
    ├── Sort Symphony DAW Bridge (VST3/AAX-specific — a different component from §8's AU bridge)
    ├── VST3 plug-in, if implemented
    └── AAX plug-in, if implemented
```

The App Store build must **not** install `.vst3`, `.aaxplugin`, helper applications, or other
executable code into shared system locations. This is a direct, current App Review Guidelines
requirement, not a cautious inference — quoting Apple's published guidelines directly:

- **2.5.2**: "Apps should be self-contained in their bundles, and may not read or write data outside
  the designated container area, nor may they download, install, or execute code which introduces or
  changes features or functionality of the app, including other apps."
- **2.4.5(ii)**: Mac App Store apps "must be packaged and submitted using technologies provided in
  Xcode; no third-party installers allowed. They must also be self-contained, single app installation
  bundles and cannot install code or resources in shared locations."
- **2.4.5(iv)**: Mac App Store apps "may not download or install standalone apps, kexts, additional
  code, or resources to add functionality or significantly change the app from what we see during
  the review process."

This doesn't affect the shipped AUv3 companion bridge at all — `AUv3Extension.appex` is embedded
directly in the App Store `Sort Symphony.app` bundle via the normal Xcode app-extension mechanism,
not separately installed or distributed. It's specifically what constrains any *future* VST3/AAX
work: the App Store app can never be the thing that installs a `.vst3`/`.aaxplugin` or a
Developer-ID-signed helper — the user would install that package independently (from the Sort
Symphony website), and the App Store app would only ever *talk to* it if already present. **This
means no second Mac App Store listing would ever be needed merely to provide VST3/AAX** — a
directly-distributed companion package would be the entire mechanism for crossing that distribution
boundary, if that work ever ships.

---

## 12. App Group entitlement policy

Shipped, not reserved: `App/Resources/SortSymphony.entitlements` and
`App/AUv3Extension/Resources/AUv3Extension.entitlements` both declare
`com.apple.security.application-groups` with `group.com.nhubbard.Sort2.mobile` — this is load-bearing
for v1, since the companion-mode bridge (§8) can't establish its Unix domain socket without it.
`SortAudioBridgePath.socketPath()` returns `nil` if the entitlement isn't resolvable at runtime (e.g.
a build/provisioning gap), and both the server (`AudioService`) and client (`SortAudioUnit`) treat
that as "bridge unavailable" — falling back to local playback, or staying silent, respectively —
rather than crashing.

If a future VST3/AAX Developer-ID bridge (§9-11) is ever built, it would likely register its own,
separate App Group identifier rather than reusing this one, since it crosses a fundamentally
different trust boundary (sandboxed App Store app ↔ non-sandboxed, independently-distributed helper)
than this one (two sandboxed processes, one hosted by a trusted first-party extension point).

---

## 13. Module structure

```text
Modules/
  SortEngineKit/            (existing, unchanged)
  AlgorithmKit/             (existing, unchanged)
  BuiltInAlgorithms/        (existing, unchanged — no longer linked by anything AU-related)

  SortAudioCore/            (SortToneEvent, RemoteControlCommand, ToneMapper, event sink)
      SortToneEvent                  — app → extension direction
      RemoteControlCommand           — extension → app direction (the remote's Transport section)
      SortAudioEventSink (protocol) / LocalToneEventSink (§4)
      ToneMapper                    — extracted from AudioService's pitch/gate-retrigger logic
      no headless driver — deleted; the AU has no sort logic of its own (§2, §7)
      no MainActor, no UI, depends only on SortEngineKit/ToneKitDSP

  ToneKitDSP/               (host-independent DSP core)
      OscillatorDSP, EnvelopeDSP, ToneRenderer, ToneCommand/ToneEvent, bounded command queue —
      ToneCommand also carries the remote's Tone-section parameters (setAttackDuration/
      setDecayDuration/setSustainLevel/setReleaseDuration/setDetuningOffset/setAmplitude)
      no AVAudioEngine, no AVAudioNode, no locks, no IPC of any kind on the render path

  ToneKitAVFoundation/      (AVFoundation adapter)
      Node, AudioEngine, AVAudioSourceNode adapter — standalone-app integration point

  SortAudioBridgeKit/       (Mac Catalyst only, `destinations: [.macCatalyst]`)
      BridgeWireCodec               — fixed-size versioned binary encode/decode for SortToneEvent (§8)
      BridgeEnvelope                — 1-byte channel tag + fixed payload, both directions share one
                                       framing shape (channel 1 = SortToneEvent, 2 = RemoteControlCommand)
      SortAudioBridgePath           — the shared App-Group-derived socket path, with a byte-length
                                       safety check
      SortAudioBridgeServer         — app side: NWListener, broadcasts to every connected client,
                                       and (now) receives RemoteControlCommands back from any of them
      SortAudioBridgeClient         — extension side: NWConnection, reconnect-on-failure loop, and
                                       (now) sendRemoteControlCommand(_:) for the remote's buttons
      depends only on SortAudioCore (for SortToneEvent/RemoteControlCommand/SortAudioEventSink)

  AudioEngineKit/           (existing, refactored again — now a bridge router)
      AudioService     — @Observable @MainActor; routes play() to the bridge (SortAudioBridgeKit,
                          Mac Catalyst only, `#if targetEnvironment(macCatalyst)`) when a client is
                          connected, else plays locally via ToneKitAVFoundation as before; enqueues
                          an immediate local .closeGate the moment a client connects (the stuck-note
                          handoff fix, §7's "Known gotchas"); exposes remoteControlHandler for the
                          app composition root to wire into SortCoordinator
      AudioPlaying, NoOpAudioService — unchanged; SortSession's call sites are unaffected

  SortAudioUnitKit/         (AUAudioUnit subclass — now a relay, not a generator)
      AUAudioUnit subclass, internalRenderBlock calling ToneRenderer.render() directly
      starts a SortAudioBridgeClient feeding a LocalToneEventSink — no sort logic of its own
      depends on SortAudioCore/ToneKitDSP/SortAudioBridgeKit — no longer on
      AlgorithmKit/BuiltInAlgorithms/SortEngineKit (nothing in this module runs a sort)
      AUParameterTree (6 params) + sendRemoteControlCommand(_:) — shipped (§7's "Plug-in UI")

  ... (SortFeature, SettingsFeature, HomeFeature, IntentsKit, DesignSystemKit, PersistenceKit,
       MathRenderingKit, ZstdKit, VisualizationKit, BuiltInVisualizers, SettingsKit — all existing,
       unaffected; none of them are linked by SortAudioUnitKit)

Deferred, not built:
  Sort Symphony DAW Bridge target      (§9-11 — separate product, Developer-ID signed, VST3/AAX-only)
  Native macOS VST3 adapter target     (§9)
  AAX adapter target                   (§10, conditional on §10's feasibility findings)

Targets/ (shipped)
  SortSymphony (App)              existing product, now owns a SortAudioBridgeServer on Mac Catalyst
  AUv3 macOS/Catalyst extension   .appExtension, destinations: [.macCatalyst] only, permanently —
                                   no iPadOS variant, condition: .when([.catalyst]) on the app's
                                   dependency on it
```

Exact names aren't load-bearing; the dependency boundaries are — in particular, nothing under
`SortAudioCore`/`ToneKitDSP`/`SortAudioUnitKit`/`SortAudioBridgeKit` may depend on `SortFeature`,
`VisualizationKit`, `DesignSystemKit`, `PersistenceKit`, `SettingsKit`, or any UI framework, ever,
and nothing under `ToneKitDSP` may depend on any IPC framework, ever — `SortAudioBridgeKit` is the
one module in this list that *does* use IPC (`Network.framework`'s Unix-domain-socket API), and it
sits entirely off the render path, feeding `LocalToneEventSink` the same way any other caller would.

### Dependency/event-flow diagram

```text
                    Algorithm / Sort Engine (standalone app only — the AU has none)
                           │
                           ▼
                      SortAudioCore
                           │
                     SortToneEvent
                           │
                      AudioService
                    ┌──────┴───────┐
                    │              │
             LocalToneEventSink   SortAudioBridgeServer.broadcast(...)
             (nothing connected)  (a bridge client is connected — replaces local playback)
                    │              │
                    ▼              │  Unix domain socket, shared App Group container
              command queue        │
                    ▼              ▼
              ToneRenderer   SortAudioBridgeClient (AU extension process)
              (ToneKitDSP)         │
                    │              ▼
                    │        LocalToneEventSink → command queue → ToneRenderer (ToneKitDSP)
                    │                                                    │
                    ▼                                                    ▼
             AVFoundation                                              AUv3
             (standalone speakers)                              (Logic Pro track)
```

The canonical sort/audio semantics and renderer remain format-neutral throughout — the same
`ToneRenderer`/`ToneKitDSP` code runs in both the standalone app's process and the AU extension's
process; only how each side's `LocalToneEventSink` gets fed differs.

### Realtime dataflow, end to end

```text
Standalone app process                              AU extension process (Logic-owned)
┌───────────────────────────────────┐     Unix      ┌─────────────────────────────────────┐
│ Sort/replay → SortToneEvent        │    domain     │ SortAudioBridgeClient                │
│   → AudioService.play(...)         │───socket─────▶│   (reconnect-on-failure loop,        │
│   → bridge connected? broadcast :  │   (App Group  │    off the render thread)            │
│     LocalToneEventSink + local     │   container)  │   → LocalToneEventSink               │
│     ToneRenderer (speakers)        │               │   → bounded command queue            │
└───────────────────────────────────┘               │ ══════ realtime boundary ══════       │
                                                      │ AUAudioUnit.internalRenderBlock       │
                                                      │   → ToneRenderer.render(frameCount,   │
                                                      │       buffer) — no locks, no IPC,     │
                                                      │       no allocation                   │
                                                      └─────────────────────────────────────┘
                                                                          ↓
                                                                Logic Pro track / mixer
                                                                          ↓
                                                             user's arbitrary effect chain
                                                                          ↓
                                                                     DAW output
```

---

## 14. Phased plan

The shipping roadmap ends at AUv3. VST3/AAX live in §9-10, not as numbered phases. Phases 0-4 built
the wrong product model (a self-contained, iPadOS+macOS generator) and are kept here for history;
Phase 5 is the correction this document now describes as current truth.

| Phase | Goal | Depends on |
|---|---|---|
| 0 | **Architecture/platform feasibility.** AU component-type test (§1). `ToneRenderer` API/command-queue design (§5). | none |
| 1 | **Shared DSP refactor.** Split `ToneKit` into `ToneKitDSP`/`ToneKitAVFoundation` (§3). Extract `EnvelopeDSP`'s per-sample math out of the `AVAudioSourceNode` closure. Introduce `ToneRenderer` as sole state owner. Replace the render-thread `Mutex` with the bounded queue + single-ownership model (§5). Preallocate render scratch storage. | Phase 0's `ToneRenderer` API shape |
| 2 | **`SortAudioCore`.** `SortToneEvent`/`ToneMapper` extracted from `AudioService` (§2). The `SortAudioEventSink`/`LocalToneEventSink` abstraction (§4). `AudioService` refactored onto `SortAudioCore` + `ToneKitAVFoundation`. Sorting algorithms stay untouched. | Phase 1 |
| 3 | **iPadOS AUv3 (superseded by Phase 5).** Built `SortAudioUnitKit` + an iPadOS extension target wired to a self-contained headless algorithm/replay driver. Registered and rendered real audio, confirmed via `pluginkit`/OS-level checks — but this entire product shape (self-contained, iPadOS-included) was the wrong one; both the headless driver and the iPadOS target were removed in Phase 5. | Phase 2 |
| 4 | **macOS AUv3 packaging spike (superseded by Phase 5).** Confirmed a Catalyst-built AUv3 extension embeds and registers cleanly on Mac (`auval -a` lists the component; `log show` confirms the extension process launches and reports ready) — this packaging finding *carried forward* into Phase 5 unchanged; only the extension's own behavior (self-contained vs. relay) and its destinations changed. | Phase 0 (Mac packaging spike), Phase 3's `SortAudioUnitKit` |
| 5 | **Companion-mode bridge correction (current architecture).** Real Logic Pro testing on Mac revealed Phases 3-4's self-contained model was wrong. Deleted `HeadlessSortAudioDriver`; built `SortAudioBridgeKit` (Unix domain socket over a shared App Group container, §8); made `AudioService` a local/bridge router; rewired `SortAudioUnit` to relay bridge events instead of running its own sort; reverted the extension to Mac Catalyst only, permanently (§7); added the App Group entitlement to both targets (§12, now shipped rather than reserved). Verified: `SortAudioBridgeKit`/`SortAudioUnitKit`/`AudioEngineKit` test suites pass on Mac Catalyst; full app+extension build succeeds with real code signing; iPad Simulator regression build confirms the extension no longer embeds there. | Phases 3-4 |
| 6 | **The remote (shipped).** A custom `AUViewController`-hosted SwiftUI view (§7's "Plug-in UI: the remote" subsection) — a Transport section (play/pause, restart, regenerate, step forward/back, sound toggle, relayed to the running app via a new reverse-direction bridge channel) and a Tone section (`AUParameterTree`-backed envelope ADSR/detune/gain sliders). Explicitly no visualization/algorithm/code UI. Found and fixed a real bug along the way: local speaker playback could keep ringing briefly after the bridge connected — `AudioService` now force-closes the local gate the moment a client connects. | Phase 5 |

**Logic Pro licensing note, still relevant:** there is a perpetual Logic Pro for Mac license
available for testing (unlike the iPad subscription this project never had access to) — this is
part of why Phase 5's Mac-only scope decision was made with real testing feedback behind it, rather
than being another unverified assumption like Phase 3's iPadOS claim was.

**The project is complete at the end of Phase 6.** Real Logic Pro testing on Mac, across both
Phase 5 and Phase 6, surfaced three real issues documented in §7's "Known gotchas" — the
`AUViewController` principal-class bug (found and fixed between Phase 5 and Phase 6, since it
blocked the bridge from ever being reached at all), the sound-must-be-on constraint, and the
stuck-local-note handoff bug. All three are fixed, not left as follow-on work.

### Deferred compatibility work (not phases — conditional, undated)

**VST3** (§9): a new, separate Developer-ID DAW Bridge (distinct from the shipped `SortAudioBridgeKit`
— §9's naming note), plug-in-side transport, native VST3 adapter, C++/Swift boundary decision,
direct distribution/notarization. Picked up only if the engineering/distribution cost is judged
worthwhile.

**AAX** (§10): feasibility/licensing/tooling evaluation first (iLok cost, Avid commercial-license
terms, whether the model maps to AAX at all); an adapter is built only if that evaluation justifies
it.

---

## 15. Open questions

Resolved by this revision:

- The product is a **live companion-mode relay** from the running standalone app, not a self-driving
  generator, not a MIDI instrument, not an audio effect.
- AUv3 is the only shipped/committed plug-in format; VST3 is designed-for-but-deferred; AAX is more
  conditional still.
- The companion-mode bridge (App Group + Unix domain socket) is shipped, load-bearing, and never part
  of the realtime render path — confirmed via real builds/tests, not just designed (§8).
- XPC is not used anywhere in this architecture, including the AU companion bridge — a correction
  from earlier drafts, which assumed XPC was the mechanism a future external bridge would use.
- **App Group**: shipped in v1 on both the app and extension (§12) — a reversal from the earlier
  "reserved, not enabled" stance, once the bridge became the core mechanism rather than a future
  option.
- **Platform scope**: Mac Catalyst only, permanently — not "iPadOS and macOS" as originally planned.
  This is the single biggest scope change in this revision (§7).
- **Self-contained vs. companion mode**: companion mode is the *only* mode. The self-contained
  headless driver was built, shipped internally, tested, and then deleted once real usage showed it
  wasn't the wanted product.
- **VST3 distribution**: unchanged from the original plan — direct, Developer ID-signed external
  distribution, never something the Mac App Store build installs; no second App Store listing
  required (§11). Renamed/clarified as a *separate* bridge from the AU's own (§9's naming note).
- **Swift/C++ interop for VST3**: still deliberately left undecided; evaluated empirically at the
  start of that deferred work (§9), not chosen now.
- **Plug-in UI scope and parameter set**: resolved and shipped (Phase 6, §7/§14) — Transport
  (play/pause, restart, regenerate, step forward/back, sound toggle) plus Tone (attack, decay,
  sustain, release, detune, gain). No MIDI input, no algorithm/visualizer/size selection.

New, from this revision:

- **AAX feasibility** — unchanged open question, unresearched beyond §10's SDK-page findings.
- **Bridge → VST3/AAX transport** — a hypothetical future VST3/AAX bridge could plausibly reuse
  `SortAudioBridgeKit`'s exact mechanism and wire codec, but the *second* boundary (bridge → an
  externally-hosted VST3/AAX binary, running inside a host process Apple doesn't govern the same way)
  remains untested and shouldn't be assumed to work identically (§9's naming note).
- **Backpressure/drop behavior on the bridge itself** — not yet built; currently only the
  *receiving*-end bounded command queue (inside `ToneKitDSP`) bounds unbounded growth, not the bridge
  transport layer itself (§8).

Carried over, still genuinely open:

1. **Whether MIDI input becomes an optional future mode** — e.g. selecting which of the running app's
   sorts to relay, or nudging playback speed remotely, layered on top of the relay rather than
   replacing it.
2. **App Store AU packaging/listing decision** — ship the AU as an update to the existing Sort
   Symphony listing (assumed throughout this document) or reconsider if real App Review feedback
   suggests otherwise.
3. **No way to feed the bridge silently** — `soundEnabled` gates both local playback and the bridge
   identically (§7's "Known gotchas"); there's no current way to hear nothing locally while still
   feeding Logic. Not clearly worth solving unless someone actually asks for it.

---

## 16. Files/modules changed in this revision (companion-mode correction)

- **Deleted**: `Modules/SortAudioCore/Sources/HeadlessSortAudioDriver.swift` and its tests — no
  self-contained fallback mode exists anywhere in this architecture now.
- **New: `Modules/SortAudioBridgeKit/`** (Mac Catalyst only) — `BridgeWireCodec`,
  `SortAudioBridgePath`, `SortAudioBridgeServer`, `SortAudioBridgeClient`, plus tests exercising a
  real Unix socket end to end. Depends only on `SortAudioCore`.
- **`Modules/SortAudioUnitKit/Sources/SortAudioUnit.swift`** — dropped `AlgorithmKit`/
  `BuiltInAlgorithms`/`SortEngineKit` imports and the headless-driver-based render loop; now starts a
  `SortAudioBridgeClient` feeding the existing `LocalToneEventSink`. A `socketPathOverride` seam
  (internal, `@testable`-only) lets tests point it at a local bridge server without the real App
  Group entitlement.
- **`Modules/AudioEngineKit/Sources/AudioService.swift`** — gained a Mac-Catalyst-only
  `SortAudioBridgeServer`, started alongside the `AVAudioEngine` in `start()`. `play()` broadcasts to
  the bridge instead of playing locally whenever a client is connected — replacing, never adding to,
  local output. iPad builds never link `SortAudioBridgeKit` at all.
- **`Tuist/ProjectDescriptionHelpers/Module.swift`** — `Module.framework` gained an optional
  `destinations` parameter (default unchanged) so `SortAudioBridgeKit` could be declared Mac Catalyst
  only without a new helper function.
- **`Project.swift`** — new `SortAudioBridgeKit` module entry (Mac-only destinations);
  `SortAudioUnitKit`'s dependencies trimmed to `SortAudioCore`/`ToneKitDSP`/`SortAudioBridgeKit`;
  `AUv3Extension` reverted to `destinations: [.macCatalyst]`; the app's dependency on it re-scoped
  with `condition: .when([.catalyst])` (the opposite of the earlier `.when([.ios])`/unconditional
  scoping across Phases 3-4).
- **`App/Resources/SortSymphony.entitlements`**, **`App/AUv3Extension/Resources/AUv3Extension.entitlements`**
  — both gained `com.apple.security.application-groups` with `group.com.nhubbard.Sort2.mobile` —
  shipped now, not reserved (§12).
- **`Modules/SortAudioUnitKit/Tests/SortAudioUnitTests.swift`** — rewritten: the old test polled for
  the headless driver's first tick; the new tests confirm silence with no bridge connection, and
  non-silent rendering once a real `SortAudioBridgeServer` (pointed at via `socketPathOverride`)
  broadcasts an event.
- **This document** — substantially rewritten (§1, §2, §4, §7, §8, §11-16) to describe the corrected
  architecture as current truth rather than accreting another patch on top of the self-contained
  model.
