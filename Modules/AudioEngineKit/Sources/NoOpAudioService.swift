/// Does nothing — stands in for the real `ToneKitAVFoundation`-backed `AudioService` until Phase 8,
/// and remains useful afterward for previews/tests that don't want a live audio engine running.
public struct NoOpAudioService: AudioPlaying {
  public init() {}
  public func start() throws {}
  public func stop() {}
  public func play(value: Int, in range: ClosedRange<Int>, holdSeconds: Double) {}
}
