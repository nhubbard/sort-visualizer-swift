import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `Shuffles.PARTIAL_REVERSE`. Reverses the whole array, then reverses the
/// middle half of it again — the outer quarters end up reversed relative to the original array,
/// while the middle half ends up back in its original order.
public struct PartialReverseShuffle: ShuffleAlgorithm {
  public let id = ShuffleID(rawValue: "partialreverse")
  public let metadata = ShuffleMetadata(displayName: "Half Reversed")
  public init() {}
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }
    engine.reversal(0, n - 1)
    engine.reversal(n / 4, (3 * n + 3) / 4 - 1)
  }
}
