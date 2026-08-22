/// The transport-neutral sort-audio event Documentation/docs/architecture/audio.md describes: the values
/// `AudioPlaying.play(...)` receives, now a standalone type so both the standalone app (via
/// `LocalToneEventSink`) and the AU extension's relay hear an identical mapping.
///
/// `index`/`arraySize` (added alongside the richer-sonification work) let `ToneMapper` derive a
/// stereo pan position from where in the array this event's value lives, not just what the value
/// is — `range` is the *value* range used for pitch mapping, a different thing entirely.
/// `operationKind` lets compares and swaps get genuinely different sonic treatment instead of the
/// identical treatment they got before this type carried it.
public struct SortToneEvent: Sendable, Equatable {
  public var value: Int
  public var range: ClosedRange<Int>
  public var holdSeconds: Double
  public var index: Int
  public var arraySize: Int
  public var operationKind: SortOperationKind

  public init(
    value: Int, range: ClosedRange<Int>, holdSeconds: Double, index: Int, arraySize: Int,
    operationKind: SortOperationKind
  ) {
    self.value = value
    self.range = range
    self.holdSeconds = holdSeconds
    self.index = index
    self.arraySize = arraySize
    self.operationKind = operationKind
  }
}
