import AlgorithmKit
import Foundation
import SortEngineKit

/// Ported from ArrayV's `Shuffles.LOG_SLOPES`. Every position `i` pulls its value from a computed
/// index (`2 * (i - power) + 1`, where `power` is the largest power of two at or below `i`) into a
/// saved copy of the original array. ArrayV hardcodes position 0 to literal `0` (its values are
/// 0-indexed); this app's values run 1..n, so position 0 gets the array's minimum instead.
///
/// Does **not** guarantee a genuine permutation of its input: at size 4, `i = 1` and `i = 2` both
/// compute index 1, so one value gets duplicated and another dropped. This is inherent to the
/// formula, not a porting bug — tracked in `NativeShuffleCorrectnessTests` alongside the curve
/// shuffles (`ShuffledCubicShuffle`/`ShuffledQuinticShuffle`) rather than the permutation-checked
/// shuffles.
public struct LogarithmicSlopesShuffle: ShuffleAlgorithm {
  public let id = ShuffleID(rawValue: "logslopes")
  public let metadata = ShuffleMetadata(displayName: "Logarithmic Slopes")
  public init() {}
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 0 else { return }
    let original = engine.values

    engine.setValue(0, original.min()!)
    for i in 1..<n {
      let log = Int(Foundation.log2(Double(i)))
      let power = Int(pow(2.0, Double(log)))
      let value = original[2 * (i - power) + 1]
      engine.setValue(i, value)
    }
  }
}
