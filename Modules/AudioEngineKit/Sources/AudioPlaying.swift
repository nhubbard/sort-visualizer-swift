/// `SortSession.startReplay` decides whether to call `play(value:in:)` based on
/// `AppSettings.soundEnabled`, and derives pitch from the current frame's value, not from
/// anything baked into the tape — notes fire at the replay engine's frame rate, so audio and
/// animation can never drift apart.
///
/// `@MainActor`, not just `Sendable`: every real caller and `AudioService`'s `ToneKit` graph are
/// already MainActor-isolated, so isolating the protocol itself is what lets `AudioService`
/// conform at all.
@MainActor
public protocol AudioPlaying: Sendable {
  func start() throws
  func stop()
  /// `holdSeconds` comes from the caller (derived from the *current* replay speed, which may
  /// have changed live since playback started) rather than this type reading a global default
  /// itself — otherwise a per-session speed override would leave notes held for a stale duration.
  func play(value: Int, in range: ClosedRange<Int>, holdSeconds: Double)
}
