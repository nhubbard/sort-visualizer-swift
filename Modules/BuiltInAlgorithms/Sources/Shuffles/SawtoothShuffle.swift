import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `Shuffles.SAWTOOTH`. The same deinterleave `FinalMergeShuffle` performs,
/// but splitting into 4 interleaved groups instead of 2 — every 4th element starting at each of
/// offsets 0, 1, 2, 3, concatenated in that order.
public struct SawtoothShuffle: ShuffleAlgorithm {
  public let id = ShuffleID(rawValue: "sawtooth")
  public let metadata = ShuffleMetadata(displayName: "Sawtooth")
  public init() {}
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    let count = 4
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
