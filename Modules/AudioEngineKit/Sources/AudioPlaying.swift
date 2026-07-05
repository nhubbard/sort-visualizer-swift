/// `ReplayEngine.stepForward()` decides *whether* to call `play(value:in:)` based on
/// `AppSettings.soundEnabled`, and derives pitch from the **current frame's value**, not from
/// anything baked into the tape — notes fire at the replay engine's frame rate, the same rate the
/// bars visually update at, so audio and animation can never drift apart (§3.1).
public protocol AudioPlaying: Sendable {
    func start() throws
    func stop()
    func play(value: Int, in range: ClosedRange<Int>)
}
