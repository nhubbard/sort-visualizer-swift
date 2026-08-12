/// The event-sink boundary `AUDIO_UNIT_PLAN.md` §4 asks for: sort/replay code and `ToneMapper`
/// never need to know where events ultimately go. `LocalToneEventSink` (this module) is the only
/// conformance that ships in this phase — an `ExternalToneEventSink` publishing over a future
/// wire protocol (§8 of the plan) is deliberately not built yet.
///
/// Deliberately *not* `@MainActor`, unlike `AudioEngineKit.AudioPlaying` — `HeadlessSortAudioDriver`
/// calls this from a plain background `Task`, not the main actor, so the protocol itself must stay
/// actor-neutral for both consumers to share it.
public protocol SortAudioEventSink: Sendable {
  func send(_ event: SortToneEvent, noteRange: ClosedRange<Int>)
}
