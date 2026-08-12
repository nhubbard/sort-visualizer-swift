/// The transport-neutral sort-audio event `AUDIO_UNIT_PLAN.md` §2/§4 describes: the same three
/// values `AudioPlaying.play(value:in:holdSeconds:)` has always received, now a standalone type
/// so both the standalone app (via `LocalToneEventSink`) and a future headless AU driver can
/// produce/consume it identically.
public struct SortToneEvent: Sendable, Equatable {
  public var value: Int
  public var range: ClosedRange<Int>
  public var holdSeconds: Double

  public init(value: Int, range: ClosedRange<Int>, holdSeconds: Double) {
    self.value = value
    self.range = range
    self.holdSeconds = holdSeconds
  }
}
