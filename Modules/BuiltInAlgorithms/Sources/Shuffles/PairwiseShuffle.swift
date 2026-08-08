import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `Shuffles.PAIRWISE`. Fully randomizes the array, pairs up each two
/// consecutive elements so the smaller of each pair comes first, then separately pigeonhole-sorts
/// the "smaller of each pair" values back into the even positions and the "larger of each pair"
/// values back into the odd positions — undoing the last compare/exchange pass a pairwise sorting
/// network would need to finish. ArrayV's own source tallies/reconstructs using each value directly
/// as a 0-indexed bucket index (its values run 0..n-1); this app's values run 1..n, so bucket
/// indices are `value - 1` and reconstructed values are `bucket + 1`.
public struct PairwiseShuffle: ShuffleAlgorithm {
  public let id = ShuffleID(rawValue: "pairwise")
  public let metadata = ShuffleMetadata(displayName: "Final Pairwise Pass")
  public init() {}
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 0 else { return }

    var i = n - 1
    while i > 0 {
      let j = Int.random(in: 0...i)
      engine.swap(i, j)
      i -= 1
    }

    var k = 1
    while k < n {
      if engine.compare(k - 1, k, by: (>)) {
        engine.swap(k - 1, k)
      }
      k += 2
    }

    var counts = [Int](repeating: 0, count: n)
    for m in 0..<2 {
      var kk = m
      while kk < n {
        counts[engine.values[kk] - 1] += 1
        kk += 2
      }

      var readIndex = 0
      var writeIndex = m
      while true {
        while readIndex < n && counts[readIndex] == 0 { readIndex += 1 }
        guard readIndex < n else { break }
        engine.setValue(writeIndex, readIndex + 1)
        writeIndex += 2
        counts[readIndex] -= 1
      }
    }
  }
}
