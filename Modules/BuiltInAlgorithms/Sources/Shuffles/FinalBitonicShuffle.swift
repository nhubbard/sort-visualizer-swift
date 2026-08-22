import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `Shuffles.FINAL_BITONIC`. Reverses the whole array, then applies the same
/// "evens forward, odds backward" fold `OrganShuffle` does — undoing the last compare/swap pass a
/// bitonic merge would need to finish sorting a fully bitonic sequence.
public struct FinalBitonicShuffle: ShuffleAlgorithm {
  public let id = ShuffleID(rawValue: "finalbitonic")
  public let metadata = ShuffleMetadata(displayName: "Final Bitonic Pass")
  public init() {}
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 0 else { return }
    if n > 1 {
      engine.reversal(0, n - 1)
    }

    var temp = [Int](repeating: 0, count: n)

    var j = 0
    var i = 0
    while i < n {
      temp[j] = engine.values[i]
      j += 1
      i += 2
    }

    j = n
    i = 1
    while i < n {
      j -= 1
      temp[j] = engine.values[i]
      i += 2
    }

    for k in 0..<n {
      engine.setValue(k, temp[k])
    }
  }
}
