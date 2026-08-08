import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `Shuffles.FINAL_MERGE`. Deinterleaves the array into two halves — every
/// even-indexed element followed by every odd-indexed element — the exact inverse of the last pass
/// a bottom-up merge would need to fully re-interleave two runs back together.
public struct FinalMergeShuffle: ShuffleAlgorithm {
  public let id = ShuffleID(rawValue: "finalmerge")
  public let metadata = ShuffleMetadata(displayName: "Final Merge Pass")
  public init() {}
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    let count = 2
    var temp = [Int](repeating: 0, count: n)
    var k = 0
    for j in 0..<count {
      var i = j
      while i < n {
        temp[k] = engine.values[i]
        k += 1
        i += count
      }
    }
    for i in 0..<n {
      engine.setValue(i, temp[i])
    }
  }
}
