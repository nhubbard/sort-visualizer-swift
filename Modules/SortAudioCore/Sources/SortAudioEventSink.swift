/// The event-sink boundary described in Documentation/docs/architecture/audio.md: sort/replay code
/// and `ToneMapper` never need to know where events ultimately go. `LocalToneEventSink` (this
/// module) wraps the in-process path; `SortAudioBridgeKit`'s client and server move the same
/// `SortToneEvent` across the companion-mode bridge without ever touching this protocol directly.
///
/// Deliberately *not* `@MainActor`, unlike `AudioEngineKit.AudioPlaying` — a bridge client calls
/// this from its own background dispatch queue, off the render thread and off the main actor, so
/// the protocol itself must stay actor-neutral for every consumer to share it.
public protocol SortAudioEventSink: Sendable {
  func send(_ event: SortToneEvent, noteRange: ClosedRange<Int>)
}
