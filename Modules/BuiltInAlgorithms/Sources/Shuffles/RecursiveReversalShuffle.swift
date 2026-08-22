import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `Shuffles.REC_REV`. Reverses the whole array, then recurses into each half
/// and reverses those too, all the way down — every range from size 2 upward gets reversed exactly
/// once, nested inside the reversal of every range that contains it.
public struct RecursiveReversalShuffle: ShuffleAlgorithm {
  public let id = ShuffleID(rawValue: "recursivereversal")
  public let metadata = ShuffleMetadata(displayName: "Recursive Reversal")
  public init() {}
  public func record(into engine: inout RecordingEngine) {
    reversalRec(&engine, a: 0, b: engine.count)
  }

  private func reversalRec(_ engine: inout RecordingEngine, a: Int, b: Int) {
    guard b - a >= 2 else { return }
    engine.reversal(a, b - 1)
    let m = (a + b) / 2
    reversalRec(&engine, a: a, b: m)
    reversalRec(&engine, a: m, b: b)
  }
}
