import AlgorithmKit
import SortEngineKit

public struct DescendingShuffle: ShuffleAlgorithm {
  public let id = ShuffleID(rawValue: "descending")
  public let metadata = ShuffleMetadata(displayName: "Descending")
  public init() {}
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    for i in 0..<(n / 2) {
      engine.swap(i, n - 1 - i)
    }
  }
}
