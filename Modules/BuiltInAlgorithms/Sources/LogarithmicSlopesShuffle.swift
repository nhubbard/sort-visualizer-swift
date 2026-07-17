import AlgorithmKit
import Foundation
import SortEngineKit

/// Ported from ArrayV's `Shuffles.LOG_SLOPES`. Every position `i` pulls its value from a computed
/// index (`2 * (i - power) + 1`, where `power` is the largest power of two at or below `i`) into a
/// saved copy of the original array — a pattern related to how a binary heap's array layout nests
/// powers-of-two-sized subtrees. ArrayV's own source hardcodes position 0 to literal value `0`,
/// which assumes 0-indexed values (0..n-1); this app's values run 1..n instead, so position 0 gets
/// the array's own minimum value in its place — the same "smallest representable value" role
/// literal `0` plays in ArrayV's convention.
///
/// Unlike every other native shuffle in this batch, this one does **not** guarantee its output is a
/// genuine permutation of its input — confirmed by hand-tracing the index formula against a plain
/// identity array under both value conventions: at size 4, `i = 1` and `i = 2` both compute index 1,
/// so whichever value sits there gets duplicated in the output while another value is dropped
/// entirely. This is inherent to the formula itself, not a porting mistake, so it's tracked in
/// `NativeShuffleCorrectnessTests` alongside the curve shuffles (`ShuffledCubicShuffle`/
/// `ShuffledQuinticShuffle`) rather than the shuffles checked for permutation.
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
