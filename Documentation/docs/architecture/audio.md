# Audio subsystem

Six modules and one app extension implement one feature: the app generates sound locally as a sort
runs, and on Mac Catalyst, relays that sound live into a DAW as a plug-in track.

## Core design: one DSP engine, thin adapters

The render logic (an oscillator plus an amplitude envelope, driven by note-on/note-off commands)
exists in one place, with no knowledge of its caller. Two hosts call the same render entry point:

```text
Standalone app:  ToneKitAVFoundation's AVAudioSourceNode render closure → ToneRenderer.render()
AUv3 extension:  SortAudioUnitKit's AUAudioUnit.internalRenderBlock     → ToneRenderer.render()
```

This is why `ToneKit` splits into two modules:

- **`ToneKitDSP`** implements the synthesis. `OscillatorDSP` (phase and frequency state, sample
  filling) and `EnvelopeDSP` (gain-envelope math) belong exclusively to `ToneRenderer`, which
  drains queued `ToneCommand`s and renders into a caller-owned buffer. This module has no
  AVFoundation import, no `MainActor`, no locks on the render path, no heap allocation, and no IPC.
  These constraints exist because this code runs on a realtime audio render thread, where any of
  them can cause an audible glitch or a dropout. The one exception to "no locks" is a bounded,
  lock-free single-producer/single-consumer queue (`ToneCommandQueue`), which carries commands into
  this realtime context. A well-formed SPSC queue's atomic operations do not block either side.
- **`ToneKitAVFoundation`** implements the AVFoundation-specific adapter: `Node`, `AudioEngine`,
  and an `AVAudioSourceNode` whose render closure calls `ToneRenderer.render(...)`. This module
  contains no synthesis logic.

Neither the standalone app nor the AU extension builds a second copy of the synth. The AU
extension does not construct an `AVAudioEngine` graph. A tone-mapping or envelope change made once
applies identically everywhere.

## `SortAudioCore`: the transport-neutral event boundary

`SortAudioCore` depends only on `SortEngineKit`, `AlgorithmKit`, and `ToneKitDSP`. It does not
depend on `SortFeature` or any UI framework. It answers one question without knowing how the
answer gets delivered: given a sort operation and a value, what tone command should play?

```swift
struct SortToneEvent { /* value, note range, hold duration */ }
enum ToneMapper { /* value → frequency, gate-retrigger-only-on-pitch-change */ }
protocol SortAudioEventSink: Sendable {
  func send(_ event: SortToneEvent, noteRange: ClosedRange<Int>)
}
final class LocalToneEventSink: SortAudioEventSink { /* enqueues into a ToneCommandQueue */ }
```

`SortAudioCore` also defines `RemoteControlCommand`, a reverse-direction type described below for
the plug-in remote's transport buttons. The rule this boundary enforces: sort code and
tone-mapping code never determine where events go. `LocalToneEventSink` does not distinguish
between a call from `AudioService` (local playback) and a call relaying an event from a different
process.

## `AudioEngineKit`: the standalone app's audio service

`AudioEngineKit` implements the standalone app's audio service: `AudioService`/`AudioPlaying`, plus
a `NoOpAudioService` for tests and previews. It depends directly on `ToneKitAVFoundation`,
`ToneKitDSP`, `SortAudioCore`, and `SettingsKit`. Swift module visibility is not transitive across
target boundaries. Even though `ToneKitAVFoundation` already depends on `ToneKitDSP`,
`AudioService` imports `ToneKitDSP` itself to construct `OscillatorDSP`/`EnvelopeDSP` values
directly.

On Mac Catalyst, `AudioEngineKit` also depends on `SortAudioBridgeKit`, using a
`.catalyst`-conditioned dependency that the iPad build never links. `AudioService`'s routing logic
is conditional: play locally unless a bridge client is connected; if one is connected, relay to it
instead of playing locally.

## Companion-mode bridge: relaying a running app's audio into a DAW

The product goal: drop the plug-in on a Logic Pro track, run a sort with sound on in the already-
running standalone app, and hear that audio arrive on the DAW track instead of the app's own
speakers, ready for Logic's effects chain. This design avoids building an effects or mixing system
inside Sort Symphony. Logic already provides one.

```text
Sort Symphony.app (server)                    AUv3Extension process (client, one per loaded instance)
    │                                                    │
    │ SortAudioBridgeServer                              │ SortAudioBridgeClient
    │   Unix domain socket, inside a                     │   connects out, retries while disconnected
    │   shared App Group container                       │
    │   (Network.framework NWListener/NWConnection)  ──▶ │
    │                                                    ▼
    │                                          LocalToneEventSink → bounded SPSC queue
    │                                          ══════════════════ realtime boundary ══
    │                                                    ▼
    │                                             ToneRenderer (render thread)
    │                                                    ▼
    │                                          AUAudioUnit.internalRenderBlock
    │                                                    ▼
    │                                             Logic Pro's track output
```

- **`SortAudioBridgeKit`** implements both ends: `SortAudioBridgeServer` (the standalone app) and
  `SortAudioBridgeClient` (the AU extension process), plus `BridgeWireCodec`. `BridgeWireCodec`
  defines a fixed-size, versioned binary struct: a version byte, `SortToneEvent`'s fields, and the
  note-range bounds, all fixed-width and big-endian, sent over a Unix domain socket bound inside a
  shared App Group container. Fixed-width fields remove the need for length-prefix framing; a
  reader always reads exactly `encodedByteCount` bytes per message. This module depends only on
  `SortAudioCore`, for the event and sink types the wire format serializes. It does not depend on
  `ToneKitDSP`.
- **The mechanism is a Unix domain socket in a shared App Group container, not XPC.** This follows
  Apple's guidance for the specific scenario: a standalone app reaching into an extension instance
  that a third-party host (Logic Pro) instantiated, not a container app talking to its own embedded
  extension. A custom XPC listener reachable from inside a third-party host's sandboxed extension
  process does not fit AUv3's design.
- **The render thread never talks to the bridge.** `internalRenderBlock` calls only
  `ToneRenderer.render(...)`. The bridge client runs its own dispatch queue off the render thread
  and calls only `LocalToneEventSink.send(...)`, which enqueues into the same lock-free queue the
  standalone app's own render code drains. If the bridge connection drops mid-render, rendering
  continues with whatever is already queued. Nothing on the render path blocks on or waits for IPC.
- **`SortAudioUnitKit`** implements the `AUAudioUnit` subclass and its `internalRenderBlock`,
  wiring a bridge client's incoming events into `ToneKitDSP`'s `ToneRenderer` through a
  `LocalToneEventSink`. It depends on `SortAudioCore`, `ToneKitDSP`, and `SortAudioBridgeKit`. It
  does not depend on `ToneKitAVFoundation` — the extension builds no `AVAudioEngine` graph — and no
  longer depends on `AlgorithmKit`, `BuiltInAlgorithms`, or `SortEngineKit`, since the extension
  does not run sorts. It relays events the running app produced.
- **`AUv3Extension`** (`App/AUv3Extension/`) contains only the `AUAudioUnitFactory`-conforming
  principal class Logic Pro instantiates. The implementation lives in `SortAudioUnitKit`.

Connection order does not matter. Logic can instantiate the AU before or after the app starts, in
either order, and either side can restart independently. The bridge client's reconnect loop and
`AudioService`'s local-playback fallback both exist so neither side assumes anything about the
other's lifecycle.

## Plug-in UI: the remote

A custom `AUViewController`-hosted SwiftUI view (`SortAudioUnitViewController` and
`SortAudioUnitParameterView`, hosted through `UIHostingController`) exposes exactly two sections.
It contains no sort visualization, algorithm detail, or code display.

- **Transport** mirrors the app's own run-control bar and menu commands: play/pause, restart (seek
  to start), regenerate (fresh shuffle, restart from scratch), step forward/back, and a sound
  toggle. These buttons are fire-and-forget. They provide no state readback from the app; the user
  confirms an action through what they hear, not through the button itself. Algorithm, visualizer,
  and size pickers, Export Tape, and the Automations menu are excluded because they expose
  algorithm detail or are not audio-relevant.
- **Tone** exposes `AUParameterTree`-backed sliders for the DSP controls `ToneKitDSP` models:
  attack, decay, sustain, and release times, detune (±50 Hz), and gain.

The transport buttons send commands to the running app: the reverse direction from
`SortToneEvent`. `SortAudioBridgeKit`'s wire format uses a one-byte channel tag
(`BridgeEnvelope`) so both directions share one fixed-size framing. Channel 1 carries the existing
`SortToneEvent` payload. Channel 2 carries a `RemoteControlCommand`, a `UInt8` enum
(`togglePlayback`, `restart`, `regenerate`, `stepForward`, `stepBackward`, `toggleSound`) defined
in `SortAudioCore` alongside `SortToneEvent`. The server gained its first receive loop; it was
previously write-only. The client gained `sendRemoteControlCommand(_:)`. Dispatching a received
command to a `SortSession` call happens in `App/Sources/Sort2App.swift`, set once at launch, since
`AudioEngineKit` cannot import `SortFeature` — that dependency runs the other way.

Tone parameter changes reuse the realtime-safety mechanism described above. An `AUParameter`'s
`implementorValueObserver` enqueues a `ToneCommand` into the same lock-free queue the frequency and
gate commands use. `implementorValueProvider` reads a lock-protected snapshot, since
`OscillatorDSP`/`EnvelopeDSP` belong exclusively to the render thread and cannot be read directly
from elsewhere.

## Why Mac Catalyst only, permanently

This restriction is a structural conclusion, not a temporary limitation pending an iPad release.
The product model requires a persistent live connection to a running standalone app instance.
iPadOS aggressively terminates backgrounded apps under memory pressure, with no recourse; this
would sever the connection at arbitrary times. macOS does not terminate background apps the same
way. A persistent live connection is architecturally sound on macOS and unsound on iPadOS,
independent of testing access.

The AU has no self-contained or headless fallback mode. It never runs a sort of its own on any
platform. If the app is not running, the plug-in stays silent.

An earlier version of this architecture built a self-contained, headless mode for iPadOS and
macOS. It shipped internally, was tested, and was deleted once real usage showed it was not the
intended product.

## Distribution and the App Store boundary

Sort Symphony ships as one Mac App Store product: the Mac Catalyst app, including the AUv3
companion-mode bridge, with the AUv3 extension embedded. This embedding uses Xcode's standard
app-extension mechanism. `AUv3Extension.appex` sits inside the App Store `Sort Symphony.app`
bundle; the app does not install or distribute it separately.

That mechanism cannot support VST3 or AAX if either is built later. App Review Guidelines prohibit
the App Store build from installing plug-in files, helper applications, or other executable code
into shared system locations:

- **Guideline 2.5.2** requires apps to be self-contained in their bundles and prohibits
  downloading, installing, or executing code that changes an app's functionality.
- **Guideline 2.4.5(ii)** requires Mac App Store apps to be self-contained, single-bundle
  installations with no third-party installers.
- **Guideline 2.4.5(iv)** prohibits downloading or installing standalone apps, kexts, or additional
  code beyond what review examined.

A future VST3 or AAX package would distribute directly from the Sort Symphony website,
Developer ID signed and notarized, installed independently by the user. The App Store app would
talk to it only if already present. This approach requires no second Mac App Store listing.

If a VST3/AAX bridge is built, it would likely register its own separate App Group identifier,
because it crosses a different trust boundary — a sandboxed App Store app talking to a
non-sandboxed, independently distributed helper — than the AUv3 bridge crosses today (two
sandboxed processes, one hosted by a trusted first-party extension point).

## The App Group entitlement

`App/Resources/SortSymphony.entitlements` and
`App/AUv3Extension/Resources/AUv3Extension.entitlements` both declare
`com.apple.security.application-groups` with `group.com.nhubbard.Sort2.mobile`. This entitlement is
shipped, load-bearing infrastructure. The companion-mode bridge cannot open its Unix domain socket
without it.

`SortAudioBridgePath.socketPath()` returns `nil` if the entitlement is not resolvable at runtime —
for example, a build or provisioning gap. Both the server (`AudioService`) and client
(`SortAudioUnit`) treat that condition as "bridge unavailable." The server falls back to local
playback; the client stays silent. Neither crashes.

## Known issues found through real Logic Pro testing

`auval` did not surface these issues. Testing in an actual DAW did. All are fixed. They are
documented here because their failure modes are easy to misdiagnose.

- **The principal class must be a real `AUViewController`, not a bare `NSObject`, even with no UI
  built.** An early version registered correctly: `auval -a` and `pluginkit` both recognized it,
  and the extension process launched cleanly. Logic would load it, sit idle for several minutes,
  then silently tear the connection down. `allocateRenderResources()` was never called, so the
  bridge client never attempted to connect. The system log explained the cause at launch:
  `misconfigured plugin; external subsystem [NSViewService_PKSubsystem] not present; possible
  missing linkage`. Every Apple AUv3 template pairs `com.apple.AudioUnit-UI` with an
  `AUViewController`-conforming principal class, even for a plug-in with no custom UI, because a
  bare `NSObject` does not provide the view-vending linkage the host's extension-point machinery
  expects. The fix replaced the plain factory with an `AUViewController` subclass that also
  conforms to `AUAudioUnitFactory`; this requires no storyboard. If a future AU-hosted extension
  registers but the host never proceeds past load, check the system log across the extension's
  full launch-to-teardown window (several minutes) for this signature before assuming it's an
  `auval`-only tooling issue.
- **Sound must be on in the app for the bridge to carry anything.** `AppSettings.soundEnabled` is
  checked before audio is handed off for playback, upstream of both local playback and the bridge
  broadcast, in the same code path. Turning sound off in the app silences Logic too, not just the
  speakers. No mechanism routes silently-generated events to the bridge only. Hearing nothing
  locally while still feeding Logic is not currently possible.
- **Logic's Record button captures MIDI, not audio, for Software Instrument tracks.** This AU never
  receives or reacts to MIDI, so hitting Record produces an empty region. "Bounce in Place," the
  usual offline workaround, also fails: it renders offline, decoupled from real time, and this AU's
  audio exists only because the standalone app enqueues it in real wall-clock time as a sort runs.
  There is nothing to bounce ahead of time. The correct capture method: route the instrument
  track's output to a bus, create a new audio track with that bus as input, record-enable the audio
  track, and press Record while a sort runs in the standalone app. Do not mute the instrument track
  during this process. Muting it silences the signal reaching the bus, not just the track's direct
  output, so the recording goes silent as well. Leaving it unmuted works correctly and does not
  double the signal, since the track's output is already redirected entirely to the bus.
- **A stuck local note during the handoff to the bridge was a real bug, now fixed.** Before the
  fix, a note already ringing locally — enqueued before an AU instance connected — kept playing
  until its hold duration expired, because the routing decision affected only new notes.
  `AudioService` now closes the local gate immediately when a new bridge connection is reported, so
  local speakers go silent right away instead of after a variable tail.
- **The bridge is off by default, with its own priming screen, because the system prompt cannot be
  customized.** The first bridge connection triggers a fixed macOS prompt ("would like to access
  data from other apps") with no way to change its wording, unlike Camera or Microphone access.
  `AppSettings.audioUnitBridgeEnabled` defaults to `false`. Settings shows explanatory text, visible
  only while the toggle is on, describing the upcoming system prompt and why it's safe to allow.
  Turning the toggle on binds the bridge's socket immediately, independent of whether a sort has
  played sound, so the system prompt and the app's own explanation both appear at the moment of
  clearest intent.

## Verified against a real DAW

Module-level test suites cover this pipeline: `SortAudioBridgeKit`'s tests run a real server and
client over a Unix socket; `SortAudioUnitKitTests` constructs a real bridge server and confirms the
AU renders silent with nothing connected, and non-silent once an event is broadcast. Beyond those
tests, the full companion-mode pipeline has been confirmed end to end on a real Logic Pro
installation. The plug-in loads, registers, and the app's local speakers go quiet once a track
connects.

## Architecture history

The product did not start as a companion-mode relay. Earlier phases built a self-contained AUv3
extension targeting both iPadOS and macOS, with its own headless algorithm/replay driver that ran
sorts independently of the standalone app. That version registered and rendered real audio,
confirmed through OS-level checks. Real Logic Pro testing on Mac showed it was the wrong product: a
plug-in that runs its own hidden sort provides none of the appeal of one that lets the user hear
the app they are actually using.

The headless driver was deleted. The iPadOS target was dropped for the platform reasons described
above. The companion-mode bridge, the remote UI, and the rest of this page's content replaced
them. The DSP core and the render path did not change during this correction. Only the path events
take to reach `ToneRenderer` changed.

## Deferred: VST3 and AAX

Neither is committed work.

**VST3.** The motivation is DAW support beyond Logic Pro (Ableton, Cubase, REAPER, Bitwig), since
Logic does not load VST3 plug-ins. If built, the core (`ToneKitDSP`, `SortAudioCore`, the canonical
event protocol) stays as it is today. Only a new adapter and a new bridge component would be
added, reusing `ToneRenderer` exactly as the AUv3 adapter does. A VST3 bridge would be a distinct
component from `SortAudioBridgeKit`, likely reusing the same Unix-domain-socket mechanism and wire
codec. The second hop — from that bridge into an externally hosted VST3 binary running inside a
host process Apple does not govern the same way — is untested and should not be assumed to work
identically. Whether to use a narrow C ABI or Swift/C++ interop for that adapter remains an open
question, to be answered empirically if this work starts.

**AAX.** This is more conditional than VST3: architecturally possible, with business and tooling
feasibility unresolved. Avid's AAX SDK page gates access behind a click-through license, requires
an iLok account for development and a physical iLok USB key for commercial signing, and discloses
no public pricing. Developers must contact Avid directly for commercial terms. Whether this app's
generator/instrument model maps cleanly to AAX is unresearched beyond these findings.

None of this blocks current work. AU, VST3, and AAX adapters are designed to stay thin,
format-specific layers over the same `ToneRenderer`/`SortAudioCore` core. No speculative
one-size-fits-all host-adapter framework is planned in anticipation of them.
