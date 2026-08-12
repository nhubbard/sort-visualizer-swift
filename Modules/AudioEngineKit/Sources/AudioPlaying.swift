import SortAudioCore

/// `SortSession.startReplay` decides whether to call `play(...)` based on
/// `AppSettings.soundEnabled`, and derives pitch from the current frame's value, not from
/// anything baked into the tape — notes fire at the replay engine's frame rate, so audio and
/// animation can never drift apart.
///
/// `@MainActor`, not just `Sendable`: every real caller and `AudioService`'s control-side calls
/// into its `ToneVoice` (`ToneKitAVFoundation`) already only ever happen from the main actor, so
/// isolating the protocol itself is what lets `AudioService` conform at all.
@MainActor
public protocol AudioPlaying: Sendable {
  func start() throws
  func stop()
  /// `holdSeconds` comes from the caller (derived from the *current* replay speed, which may
  /// have changed live since playback started) rather than this type reading a global default
  /// itself — otherwise a per-session speed override would leave notes held for a stale duration.
  /// `index`/`arraySize` drive stereo panning (§3 of the richer-sonification work); `operationKind`
  /// lets compares/swaps/value-writes get genuinely different sonic treatment.
  func play(
    value: Int, in range: ClosedRange<Int>, holdSeconds: Double, index: Int, arraySize: Int,
    operationKind: SortOperationKind)
}
