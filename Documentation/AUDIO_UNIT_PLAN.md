# Sort Symphony as an Audio Unit — Implementation Plan

Status: **planning only, nothing built. Third and final pre-implementation draft.** This revision
commits scope and reserves an expansion path; it does not change the core architecture the second
draft established (the sort-driven generator model, `SortAudioCore`, the `ToneKitDSP`/
`ToneKitAVFoundation` split, realtime-safe rendering). See `ARCHITECTURE_V2.md`/
`IMPLEMENTATION_PLAN.md` for the existing app's shipped design this plan builds alongside.

**What this draft commits to, up front:**

1. **AUv3 is the committed v1 feature** — the only plug-in format actually being built.
2. **The AU is fully self-contained and requires no custom IPC** to operate — it never talks to
   anything outside its own process to render audio.
3. **The core event/DSP architecture (`SortAudioCore`, `ToneKitDSP`, `ToneRenderer`) is
   transport- and plug-in-format-neutral by design**, so a future external transport or plug-in
   format is an additional adapter, not a rewrite.
4. **The Mac architecture reserves and validates an App Group/XPC path** for a possible future
   external DAW bridge — validated in a Phase 0 spike, but not shipped in the initial build.
5. **XPC is never part of the realtime audio-render path**, full stop — not now, not in any future
   bridge design.
6. **VST3 is optional future compatibility, delivered outside the Mac App Store** via a separately
   distributed, Developer ID-signed bridge — not a Phase in the initial roadmap.
7. **AAX is a still-more-conditional future target**, gated on real licensing/tooling cost, using
   the same bridge/core if it's ever pursued.
8. **Nothing in the initial AU implementation requires Swift/C++ interoperability** — that question
   is deferred entirely to whenever VST3 work actually starts.
9. **The initial project is considered complete once AUv3 works robustly on iPadOS and macOS** —
   there is no Phase 6 in the committed roadmap; VST3/AAX live in a separate, non-numbered
   "deferred compatibility" section.

---

## 1. The product model: a live, self-contained sort-audio generator (AUv3, committed)

The goal is to expose the sonification a running sort/replay already produces as a live, continuous
audio source inside a DAW — something you drop on a track, hit play, and hear the sort's own tones
come out, ready for Logic's (or another AU host's) effects chain on top.

```text
Sort Symphony
    ↓
SortAudioCore
    ↓
ToneKitDSP
    ↓
AUv3
    ↓
Logic Pro / other AUv3 hosts
```

for **iPadOS** and **macOS through the existing Mac Catalyst product**, using whichever AU packaging
strategy the Phase 0 spike (§6) proves reliable. This is the entire committed v1 scope. VST3 and AAX
are addressed in §9-10 as deferred, conditional compatibility work — the architecture below is
written so that work is possible later without a rewrite, not so that it's promised.

Explicitly **not** in scope for v1:

- No bounced/pre-rendered audio file.
- No requirement that the DAW supply MIDI notes as the source of truth for pitch/timing.
- No incoming audio signal that Sort Symphony transforms (`ToneKit` has no audio-input processing
  path today — see `NOTICE.md`'s "no Fader... no MIDI, automation" scope note — and this plan
  doesn't add one).
- No rewriting of individual sorting algorithms around AU/VST/MIDI/DAW-transport concepts. Every
  algorithm in `BuiltInAlgorithms` stays exactly what it is today: a pure, synchronous producer of
  `SortOperation`s against `RecordingEngine`, with zero awareness that a plug-in host, or any future
  external transport, might ever consume its output.

**Component type: what Logic actually needs to see.** AUv3 has a real `kAudioUnitType_Generator`
category (audio out, no MIDI in, no audio in) that matches this product's actual behavior more
precisely than an instrument does. Research turned up no confirmed, current evidence of Logic Pro
exposing a user-installed `kAudioUnitType_Generator` plug-in the way it exposes Instruments —
Generator subtypes appear mostly as Apple-internal utility units. By contrast, there's a real,
working precedent for this exact product shape registered as an **instrument** (`aumu`): Wotja
(Intermorphic) ships as an AUv3 hosted successfully in Logic Pro that generates music from its own
internal engine autonomously, with MIDI as optional/secondary control rather than the source of
truth. The pragmatic, proven-in-the-wild answer is: **register as `aumu` for host compatibility and
DAW-track presentation, but architect the plug-in so incoming MIDI is never load-bearing** — the
sort/replay engine drives its own tone generation regardless of whether any MIDI ever arrives.
Confirming this against real Logic behavior (iPad and Mac) is Phase 0 work (§11), not assumed
further. Optional MIDI *input* (e.g. to select an algorithm, or nudge speed) remains a plausible
future feature, not a v1 requirement (§12).

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

`SortAudioCore` also owns something the standalone app has never needed: **a headless driver that
picks and runs an algorithm/shuffle/size on its own**, since a plug-in instance has no
`SortSession`/UI feeding it choices — it must be self-sufficient the moment Logic instantiates it
(§6). This driver depends only on `SortEngineKit`/`AlgorithmKit`/`BuiltInAlgorithms` — never on
`SortFeature` (which pulls in `VisualizationKit`, `DesignSystemKit`, `PersistenceKit`,
`MathRenderingKit`, `ZstdKit`, none of which a plug-in should link). What exactly it picks (fixed
algorithm, cycling, parameter-selected) is open (§12).

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

## 4. A transport-neutral event boundary, designed in now

`SortAudioCore` must produce a canonical logical event representation that doesn't care whether the
consumer is the standalone renderer, the AUv3 extension, or — someday — an external transport. This
is the one piece of new abstraction this draft asks for beyond the second draft, because retrofitting
it later would mean touching `SortAudioCore` a second time after the AU already ships.

```text
SortToneEvent
    │
    ├── LocalEventSink → realtime SPSC queue → ToneRenderer      (ships in v1)
    │
    └── ExternalEventSink                                        (future, macOS-only, §8)
            ↓
        XPC serialization
            ↓
        DAW Bridge
            ↓
        plug-in event ingress
            ↓
        realtime SPSC queue → ToneRenderer
```

Proposed shape (exact names aren't load-bearing):

```text
protocol SortAudioEventSink { func send(_ event: SortToneEvent) }

struct LocalToneEventSink: SortAudioEventSink {
    // wraps the bounded SPSC queue feeding ToneRenderer directly, in-process
}

// Future, not implemented now:
// struct ExternalToneEventSink: SortAudioEventSink { ... publishes over the wire protocol in §5 ... }
```

**The rule this exists to enforce: sort code and tone-mapping code must never know or care where
events ultimately go.** `SortAudioCore`'s headless driver and `ToneMapper` emit `SortToneEvent`s to
whatever `SortAudioEventSink` they were configured with; only the sink implementation differs between
"this process's own render thread" (v1, everywhere) and "somewhere else, over a wire" (deferred,
§8-9). `LocalToneEventSink` is the only sink implemented in v1 — it's what both the standalone app
and the AU extension use.

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

## 7. iPadOS and macOS/Catalyst: the AUv3 target itself

### iPadOS — required, self-contained

Logic Pro for iPad hosts ordinary iPadOS AUv3 App Extensions installed from the App Store; there's
no separate Logic-specific SDK and no Catalyst involvement, since the app already ships a real
iPadOS build (`.iPad` is one of `Module.destinations`' two entries,
`Tuist/ProjectDescriptionHelpers/Module.swift:9`).

The extension must be **self-contained enough that Logic owns its entire lifetime**:

```text
Logic launches AU
    ↓
AU owns SortAudioCore headless driver
    ↓
sort runs
    ↓
LocalToneEventSink → ToneRenderer
    ↓
audio
```

It cannot assume the standalone Sort Symphony app is foregrounded, running, or even installed — this
is particularly important on iPadOS, where there is no external-bridge concept at all (§8 is
macOS-only). Ideally the *exact same* `SortAudioCore` headless driver runs inside both the standalone
app target and the AU extension target.

### macOS / Mac Catalyst — test reality before choosing, in this order

This project is Mac Catalyst end to end today — no native macOS (AppKit or macOS-native SwiftUI)
target exists anywhere in the repository. That's the fact driving the packaging uncertainty below;
it isn't evidence any particular approach is required.

**Test in this order, cheapest/most-likely-to-just-work first:**

1. **Test a normal Catalyst-built AUv3 extension, embedded in the existing Catalyst app, on the
   current Xcode 26 toolchain first.** Older developer-forum friction reports
   (`supportedViewConfigurations` sizing, `auval` validation issues) predate this toolchain — don't
   rule this out on old evidence when it's cheap to simply try it.
2. **If (1) has real, current registration/validation problems**, test whether a plain native-macOS
   (non-Catalyst) AU extension target can be embedded inside the existing Catalyst app's Mac build —
   one App Store listing, one container product, a fully native-macOS `.appex`. Viable because
   `ToneKitDSP`/`SortAudioCore` have zero UIKit/AppKit dependency by construction.
3. **Only if both (1) and (2) prove unsupported or unreliable**, fall back to a small, genuinely
   separate native-macOS container app target existing purely to hold the AU extension on Mac.

Do not permanently complicate the product based only on historical/toolchain-specific Catalyst-AU
reports before the current configuration has actually been tested.

**The AU itself remains completely self-contained and in-process regardless of which packaging
option above is chosen** — none of the three options change the render-time architecture from §5-6.

---

## 8. Reserved (not shipped) macOS expansion path: App Group/XPC bridge

This section changes the previous draft's conclusion. XPC is still never part of the realtime
render path (§5's hard rule stands unmodified) — but on macOS specifically, the architecture should
**leave a validated, working path** for a future external bridge, rather than merely noting XPC as
"available if someone wants it later."

**Why this is worth reserving now, concretely:** the App Store build must not install `.vst3`,
`.aaxplugin`, or helper applications into shared system locations (§9's citations). If VST3/AAX
support is ever built, the only App Store-compliant way to get that logical sort-audio event stream
to externally distributed plug-in code is a separate, directly-distributed companion app — and that
companion app needs *some* way to receive live events from the running, sandboxed, App Store copy of
Sort Symphony. App Groups are Apple's documented mechanism for exactly this: Apple's current App
Groups documentation states the entitlement's purpose is to "enable communication and data sharing
between multiple installed apps created by the same developer," and the (now-retired, but
technically still-accurate and consistently corroborated) App Sandbox Design Guide described the
underlying mechanism more specifically — member apps "share Mach and POSIX semaphores and... certain
other IPC mechanisms," with one member of a group able to be sandboxed while another is not. That
sandboxed/nonsandboxed pairing is precisely the shape needed here: the App Store `Sort Symphony.app`
(sandboxed) and a separately distributed `Sort Symphony DAW Bridge` (Developer ID-signed, notarized,
not sandboxed) sharing one App Group.

```text
Mac App Store Sort Symphony
        │
        │ App Group / XPC
        ▼
Sort Symphony DAW Bridge
Developer-ID signed + notarized
        │
        ├──── future VST3 integration
        │
        └──── possible future AAX integration
```

The purpose of the bridge is to let the App Store version of Sort Symphony emit the same logical
`SortToneEvent` stream to externally distributed plug-in infrastructure, without the App Store app
itself ever installing executable plug-in code (which guideline 2.5.2/2.4.5 forbid — §9).

**Hard rule, restated from §5 in this specific context:** neither a future VST3 nor AAX
`process()`/render callback may synchronously call XPC, wait for the bridge, perform filesystem IPC,
allocate IPC messages, acquire cross-process locks, or block waiting for the Sort Symphony app or the
bridge. The bridge is a **control/event transport**, never an audio-rendering dependency:

```text
Sort Symphony.app
    │
    │ versioned SortToneEvent stream (§ future wire protocol below)
    ▼
XPC / App Group transport
    │
    ▼
DAW Bridge
    │
    │ non-realtime transport
    ▼
plug-in-side event ingress
    │
    ▼
bounded realtime-safe queue
════════════════════════════ realtime boundary
    ▼
ToneRenderer
    ↓
DAW audio buffer
```

### Future external transport: wire-protocol design requirements (design only, not implemented)

To avoid discovering later that `SortToneEvent`/`ToneCommand` can't be transported cleanly, the
*requirements* for a future external event protocol are worth fixing now, without building it:

- Explicitly versioned, with a defined incompatibility-reporting path.
- Format-neutral — not named or shaped around VST specifically, since AAX may reuse the same
  transport.
- Based on semantic `SortToneEvent`/`ToneCommand` concepts, not PCM — the bridge moves *events*, not
  audio.
- Capable of carrying timestamps/sample timing where useful.
- Capable of identifying a stream/session (so a bridge serving multiple concurrent plug-in instances,
  or reconnecting mid-session, isn't ambiguous).
- Capable of reconnecting cleanly after either side restarts.
- Explicit about bounded queues, backpressure, and drop behavior when the consumer falls behind.
- Independent of Swift object identity or pointers.
- Independent of AU/VST/AAX SDK types.

**Do not prematurely pick NSXPC-specific classes as the canonical model.** The logical protocol
should survive if the eventual transport turns out to be XPC, shared memory, Unix sockets, or some
combination — a simple, fixed, value-semantic wire representation (plain structs/enums with explicit
versioned encoding, not `NSSecureCoding` classes tied to one transport) is preferable. This design
work belongs in the initial architecture; building the actual bridge does not.

### Phase 0 feasibility spike (throwaway, not production)

Even though the bridge doesn't ship in v1, Phase 0 should prove the assumption the entire deferred
VST3/AAX path depends on:

```text
sandboxed Mac Catalyst test app
        ↕
App Group / XPC
        ↕
Developer-ID-signed nonsandboxed helper
```

Goal: establish only that —

- the App Store-compatible sandboxed side can establish the intended IPC relationship;
- a separately distributed, Developer ID-signed helper can participate using this project's real
  Team ID/App Group configuration;
- reconnect/relaunch behavior (either side restarting independently) is understood;
- no temporary sandbox exceptions or private APIs are required.

**Do not turn this into production bridge code.** It's a disposable spike whose only output is
confidence (or a documented blocker) plus notes feeding §9's "at the start of that work" list.

Also, explicitly: this spike tests only the **App Store app ↔ Developer-ID helper** boundary. It says
nothing about the separate, still-unresolved **bridge → DAW plug-in** boundary — a VST3/AAX binary
runs inside a host-controlled process Apple doesn't govern the same way, so don't assume that leg
will necessarily be XPC or App-Group access too. That second boundary gets tested against real DAW
hosts only when VST3/AAX work actually starts (§9-10).

---

## 9. Deferred Compatibility: VST3

Logic Pro never loads VST3 — the reason to want it at all is other DAWs on macOS (Ableton, Cubase,
REAPER, Bitwig, etc.). **VST3 is not a committed phase.** It's a described-but-deferred compatibility
target, conditional on the engineering/distribution cost being worthwhile once AUv3 has shipped.

The core stays exactly what §1-6 already builds:

```text
ToneKitDSP
SortAudioCore
canonical event protocol (§4, §8)
```

A future VST3 effort would *add*, without touching the core:

```text
Developer-ID DAW Bridge (§8)
        +
native macOS VST3 adapter
        +
bridge-to-plugin event transport (§8's still-unresolved second boundary)
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

**Architectural goal only:** nothing in `SortAudioCore`, `ToneKitDSP`, the event wire protocol (§8),
or the bridge should assume VST3-specific semantics in a way that would preclude a future AAX
adapter reusing the same core and bridge. **AAX is not in the implementation schedule.** It is
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
Initial product (committed):

Apple App Store
    ↓
Sort Symphony
    ├── iPadOS app
    ├── Mac Catalyst app
    └── embedded AUv3 extension(s)

Possible future external compatibility package (deferred, conditional):

Sort Symphony website / direct distribution
    ↓
Developer-ID signed + notarized Mac package
    ├── Sort Symphony DAW Bridge
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

Together these mean the App Store `Sort Symphony.app` can never be the thing that installs the
`DAW Bridge`, a `.vst3`, or an `.aaxplugin` — the user installs the bridge/plug-in package
independently (from the Sort Symphony website), and the App Store app only ever *talks to* it if
already present, via the App Group path in §8. **This means no second Mac App Store listing is ever
needed merely to provide VST3/AAX** — the directly-distributed companion package is the entire
mechanism for crossing that distribution boundary, if that work ever ships.

---

## 12. App Group entitlement policy

There is now a concrete anticipated future use for an App Group (§8) — the plan should no longer
say "no need identified." However:

> The architecture reserves an App Group/XPC bridge path and Phase 0 validates it, but the
> production App Group entitlement is added to shipping targets only when the external bridge
> feature is actually implemented.

Concretely: `App/Resources/SortSymphony.entitlements` gets no new entitlement for the v1 AU ship.
The intended App Group identifier may be *reserved/registered* on the Apple Developer portal during
development (registration is required regardless of when the entitlement is actually turned on, per
current Apple guidance that app group IDs must be registered to the team before use), but no shipping
target declares `com.apple.security.application-groups` until the bridge feature is real. This keeps
the initial App Store submission as simple as possible while confirming — via the Phase 0 spike — that
the expansion path actually works before committing to it in a shipping entitlement.

---

## 13. Module structure

```text
Modules/
  SortEngineKit/            (existing, unchanged)
  AlgorithmKit/             (existing, unchanged)
  BuiltInAlgorithms/        (existing, unchanged)

  SortAudioCore/            (NEW)
      SortToneEvent
      SortAudioEventSink (protocol) / LocalToneEventSink (§4)
      ToneMapper                    — extracted from AudioService's pitch/gate-retrigger logic
      headless algorithm/replay driver — for self-contained plug-in operation (§7)
      no MainActor, no UI, depends only on SortEngineKit/AlgorithmKit/BuiltInAlgorithms

  ToneKitDSP/               (NEW — replaces most of today's ToneKit)
      OscillatorDSP, EnvelopeDSP, ToneRenderer, ToneCommand/ToneEvent, bounded SPSC queue
      no AVAudioEngine, no AVAudioNode, no locks, no IPC of any kind on the render path

  ToneKitAVFoundation/      (NEW — replaces the AVFoundation half of today's ToneKit)
      Node, AudioEngine, AVAudioSourceNode adapter — standalone-app integration point

  AudioEngineKit/           (existing, refactored)
      AudioService                  — thin @MainActor wrapper over SortAudioCore + ToneKitAVFoundation
      AudioPlaying, NoOpAudioService — unchanged; SortSession's call sites are unaffected

  SortAudioUnitKit/         (NEW, Phase 3-4)
      AUAudioUnit subclass, internalRenderBlock calling ToneRenderer.render() directly
      owns/hosts a SortAudioCore headless driver + LocalToneEventSink per plug-in instance
      AUParameterTree (scope per §12's open questions)

  ... (SortFeature, SettingsFeature, HomeFeature, IntentsKit, DesignSystemKit, PersistenceKit,
       MathRenderingKit, ZstdKit, VisualizationKit, BuiltInVisualizers, SettingsKit — all existing,
       unaffected; none of them are linked by SortAudioUnitKit)

Deferred, not built in v1:
  Sort Symphony DAW Bridge target      (§8 — separate product, Developer-ID signed)
  Native macOS VST3 adapter target     (§9)
  AAX adapter target                   (§10, conditional on §10's feasibility findings)

Targets/ (v1, committed)
  SortSymphony (App)              existing, unchanged product
  AUv3 iPadOS extension           NEW, Phase 3 — .appExtension, .iPad only
  AUv3 macOS/Catalyst extension   NEW, Phase 4 — packaging per §7's tested order
```

Exact names aren't load-bearing; the dependency boundaries are — in particular, nothing under
`SortAudioCore`/`ToneKitDSP`/`SortAudioUnitKit` may depend on `SortFeature`, `VisualizationKit`,
`DesignSystemKit`, `PersistenceKit`, `SettingsKit`, or any UI framework, ever, and nothing under
`ToneKitDSP` may depend on any IPC/XPC framework, ever.

### Revised dependency/event-flow diagram

```text
                    Algorithm / Sort Engine
                           │
                           ▼
                      SortAudioCore
                           │
                     SortToneEvent
                    ┌──────┴───────┐
                    │              │
             LocalEventSink   ExternalEventSink
             (v1, shipped)    (deferred, §8, macOS-only)
                    │              │
                    ▼              ▼
                SPSC queue      DAW Bridge
                    │              │
                    ▼              │
                ToneRenderer       │
              (ToneKitDSP)         │
                    │              │
              ┌─────┴─────┐        │
              │           │        │
       AVFoundation      AUv3      │  future plug-in ingress
       (standalone)    (v1, shipped)   ┌────┴────┐
                                        ▼         ▼
                                      VST3       AAX
                                    (§9)        (§10)
                                        │         │
                                        └────┬────┘
                                             ▼
                                      ToneRenderer
                                      (same ToneKitDSP)
```

The canonical sort/audio semantics and renderer remain format-neutral throughout; external transport
is a separate, clearly-bounded concern that only exists on the right-hand side of the diagram, which
is entirely unbuilt in v1.

### Realtime dataflow, end to end (v1 scope)

```text
AU extension process (Logic-owned lifetime)
┌─────────────────────────────────────────────────────────────────────┐
│ SortAudioCore headless driver                                       │
│   picks algorithm/shuffle/size → RecordingEngine → Tape              │
│   drives ReplayEngine at its own pacing                              │
│     → SortToneEvent(value, range, holdSeconds) per operation         │
│     → ToneMapper → ToneCommand(frequency, gate, [sample offset])     │
│     → LocalToneEventSink → bounded SPSC queue                        │
│ ════════════════════════════════ realtime boundary ═══════════════   │
│ AUAudioUnit.internalRenderBlock                                     │
│   → ToneRenderer.render(frameCount, buffer)   — no locks, no IPC,    │
│       no allocation; drains due ToneCommands, updates DSP state,     │
│       fills caller-owned buffer                                      │
└─────────────────────────────────────────────────────────────────────┘
                                    ↓
                          Logic Pro track / mixer
                                    ↓
                       user's arbitrary effect chain
                                    ↓
                              DAW output
```

---

## 14. Phased plan

The shipping roadmap ends at AUv3. VST3/AAX live in §9-10, not as numbered phases.

| Phase | Goal | Depends on |
|---|---|---|
| 0 | **Architecture/platform feasibility.** AU component-type test (§1). iPad AU loading validation. Catalyst/macOS AU packaging spike (§7's tested order). `ToneRenderer` API/SPSC design (§5). Define the versioned, transport-neutral event/wire model (§8) as a design artifact. **Also**: the App Group/XPC Catalyst-sandboxed ↔ Developer-ID-helper feasibility spike (§8), throwaway code only. | none |
| 1 | **Shared DSP refactor.** Split `ToneKit` into `ToneKitDSP`/`ToneKitAVFoundation` (§3). Extract `EnvelopeDSP`'s per-sample math out of the `AVAudioSourceNode` closure. Introduce `ToneRenderer` as sole state owner. Replace the render-thread `Mutex` with the bounded queue + single-ownership model (§5). Preallocate render scratch storage. Verify the standalone app sounds/behaves identically (regression-test against `Modules/ToneKit/Tests/{OscillatorTests,AmplitudeEnvelopeTests,NodeTests}.swift` and `Modules/AudioEngineKit/Tests/{AudioServiceTests,NoOpAudioServiceTests}.swift`, re-homed across the new modules). | Phase 0's `ToneRenderer` API shape |
| 2 | **`SortAudioCore`.** `SortToneEvent`/`ToneMapper` extracted from `AudioService` (§2). Headless algorithm/replay driver (§7). **Also establish the `SortAudioEventSink`/`LocalToneEventSink` abstraction (§4)** used by both v1 consumers now, with the `ExternalEventSink` shape documented but not implemented. `AudioService` refactored onto `SortAudioCore` + `ToneKitAVFoundation`. Sorting algorithms stay untouched. | Phase 1 |
| 3 | **iPadOS AUv3.** `SortAudioUnitKit` + the iPadOS extension target, wiring the headless driver directly into `internalRenderBlock` via `LocalToneEventSink`/`ToneRenderer`. Test in Logic Pro for iPad; verify the plug-in survives without the standalone app running. | Phase 2, informed by Phase 0's component-type finding |
| 4 | **macOS AUv3.** Whichever packaging option §7's tested order lands on. Validate with `auval` and real Logic Pro on Mac. | Phase 0 (Mac packaging spike), Phase 3's `SortAudioUnitKit` |
| 5 | **Parameters/presets/UI and shipping hardening.** Decide which sort/synth controls belong in the plug-in (§12) and expose them via `AUParameterTree`. App Review documentation/testing for the AU submission. No App Group entitlement added at this phase (§12). | Phases 3-4 |

**The initial project is complete at the end of Phase 5.**

### Deferred compatibility work (not phases — conditional, undated)

**VST3** (§9): Developer-ID DAW Bridge, XPC publisher, plug-in-side transport, native VST3 adapter,
C++/Swift boundary decision, direct distribution/notarization. Picked up only if the
engineering/distribution cost is judged worthwhile after v1 ships.

**AAX** (§10): feasibility/licensing/tooling evaluation first (iLok cost, Avid commercial-license
terms, whether the generator model maps to AAX at all); an adapter is built only if that evaluation
justifies it.

---

## 15. Open questions

Resolved by this revision:

- The product is a **sort-driven live audio generator**, not a MIDI instrument or an audio effect.
- AUv3 is the committed v1 target; VST3 is designed-for-but-deferred; AAX is more conditional still.
- The AU is fully self-contained on both iPadOS and macOS and requires no custom IPC to render audio.
- XPC is never part of the realtime render path, in v1 or in any future bridge design.
- **App Group need**: no longer "none identified" — it's *anticipated* for a future external bridge
  (§8) and validated by a Phase 0 spike, but the production entitlement is **not** enabled in the
  initial shipping build (§12).
- **VST3 distribution**: direct, Developer ID-signed external distribution — never something the Mac
  App Store build installs; no second App Store listing required (§11).
- **Swift/C++ interop for VST3**: deliberately left undecided; evaluated empirically at the start of
  that deferred work (§9), not chosen now.
- **Self-contained AU vs. companion-driven mode**: self-contained (`LocalEventSink`) is required and
  is the only thing v1 ships; companion mode (`ExternalEventSink`) is future, macOS-only, and
  contingent on the bridge ever being built.

New, from this revision:

- **AAX feasibility** — is the real all-in cost (iLok hardware, Avid's undisclosed commercial
  licensing terms, any PACE signing fees) and market case (Pro Tools specifically) worth it, once
  VST3 (if ever) has shipped? Unresearched beyond §10's SDK-page findings.
- **Bridge → VST3/AAX transport** — genuinely separate from the App Store-app-to-bridge XPC path
  validated in Phase 0; must be tested against real DAW hosts only when that work starts, not assumed
  to be the same mechanism (§8).

Carried over, still genuinely open:

1. **Exact Mac AU packaging strategy** — resolved empirically by §7's tested order (Phase 0/4).
2. **Exact Logic-visible component type/presentation** — `aumu` with autonomous internal generation
   (Wotja precedent) vs. `kAudioUnitType_Generator` if Phase 0 testing finds current Logic actually
   surfaces third-party Generator-type units well.
3. **Plug-in UI scope** — a custom view (possibly reusing `VisualizationKit`/`BuiltInVisualizers`
   somehow) versus a host-generic parameter view only.
4. **Automatable parameter set** — candidates include algorithm choice, shuffle choice, array size,
   playback speed, note range, and envelope ADSR; none committed yet (Phase 5).
5. **Whether MIDI input becomes an optional future mode** — e.g. selecting an algorithm or modulating
   speed, layered on top of the self-driving generator rather than replacing it.
6. **App Store AU packaging/listing decision** — ship the AU as an update to the existing Sort
   Symphony listing (assumed throughout this document) or reconsider if Phase 0 findings suggest
   otherwise.

---

## 16. Files/modules expected to change (v1 scope only)

- **`Modules/ToneKit/`** — retired as a single module. `Oscillator.swift`'s `fill()` becomes
  `OscillatorDSP` in `ToneKitDSP` largely as-is. `AmplitudeEnvelope.swift` splits: `nextGain()`'s math
  becomes `EnvelopeDSP` in `ToneKitDSP`; the `AVAudioSourceNode` ownership/render-closure wiring
  becomes the adapter in `ToneKitAVFoundation`, now calling `ToneRenderer.render(...)` instead of
  doing envelope math and `Mutex` locking inline. `Node.swift` moves to `ToneKitAVFoundation`
  unchanged.
- **`Modules/AudioEngineKit/Sources/AudioService.swift`** — refactored to depend on `SortAudioCore`
  (for `ToneMapper`) and `ToneKitAVFoundation` (for the engine) instead of instantiating
  `Oscillator`/`AmplitudeEnvelope` and doing pitch mapping itself. `AudioPlaying`/`NoOpAudioService`
  unaffected; `SortSession`'s call sites (`Modules/SortFeature/Sources/SortSession.swift:471-474`)
  don't change.
- **New: `Modules/SortAudioCore/`** — `SortToneEvent`, `ToneMapper`, `SortAudioEventSink`/
  `LocalToneEventSink`, and the headless algorithm/replay driver. Depends only on
  `SortEngineKit`/`AlgorithmKit`/`BuiltInAlgorithms`.
- **New: `Modules/ToneKitDSP/`** — `OscillatorDSP`, `EnvelopeDSP`, `ToneRenderer`,
  `ToneCommand`/`ToneEvent`, the bounded SPSC queue. No AVFoundation import; no IPC import.
- **New: `Modules/ToneKitAVFoundation/`** — `Node`, `AudioEngine`, the `AVAudioSourceNode` adapter.
- **New: `Modules/SortAudioUnitKit/`** — the `AUAudioUnit` subclass, `internalRenderBlock`, parameter
  tree, and the glue instantiating a `SortAudioCore` headless driver + `LocalToneEventSink` per
  plug-in instance.
- **`Project.swift` / `Tuist/ProjectDescriptionHelpers/Module.swift`** — needs new support for
  `.appExtension` product targets (no precedent exists in the current helper, which only has
  `Module.framework` for framework+test-target pairs) and whatever new destination (native `.mac`,
  alongside the existing `.iPad`/`.macCatalyst`) the Phase 0/4 Mac-packaging spike lands on.
- **`App/Resources/SortSymphony.entitlements`** — **no change** in v1 (§12); an App Group entry is
  added only when/if the deferred bridge (§8) is actually implemented.
- **Test coverage**: `Modules/ToneKit/Tests/{OscillatorTests,AmplitudeEnvelopeTests,NodeTests}.swift`
  and `Modules/AudioEngineKit/Tests/{AudioServiceTests,NoOpAudioServiceTests}.swift` re-homed across
  the new module split, plus new coverage for `ToneRenderer`'s realtime-safety invariants (no
  allocation, bounded-queue behavior under overflow) — properties the old design was never tested
  against.
- **Nothing else changes in v1** — no bridge target, no VST3/AAX adapter target, and no entitlement
  changes beyond what's listed above. §8's Phase 0 spike is explicitly throwaway and doesn't land in
  any shipping target.
