/// `SortSession.startReplay` decides *whether* to call `play(value:in:)` based on
/// `AppSettings.soundEnabled`, and derives pitch from the **current frame's value**, not from
/// anything baked into the tape — notes fire at the replay engine's frame rate, the same rate the
/// bars visually update at, so audio and animation can never drift apart (§3.1).
///
/// `@MainActor`, not just `Sendable`: every real caller (`SortSession`, `ReplayEngine`'s playback
/// loop) is already MainActor-isolated, and `AudioService`'s `ToneKit` graph is only ever touched
/// from there — isolating the protocol itself, rather than leaving conformances to reconcile
/// isolation ad hoc, is what lets `AudioService` (a `@MainActor` class) conform at all.
@MainActor
public protocol AudioPlaying: Sendable {
    func start() throws
    func stop()
    /// `holdSeconds` comes from the caller (derived from the *current* replay speed, which may
    /// have changed live since playback started) rather than this type reading a global default
    /// itself — otherwise a per-session speed override would leave notes held for a stale duration.
    func play(value: Int, in range: ClosedRange<Int>, holdSeconds: Double)
}
