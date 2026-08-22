import AlgorithmKit
import Foundation
import SortEngineKit

/// Ported from `Legacy/Shared/Data/Primary/ShuffleMethod.swift`'s `genShuffledN(power: 5, ...)`:
/// remaps each position through a quintic curve to get a skewed value distribution, then
/// Fisher-Yates shuffles the result.
public struct ShuffledQuinticShuffle: ShuffleAlgorithm {
  public let id = ShuffleID(rawValue: "shuffledquintic")
  public let metadata = ShuffleMetadata(displayName: "Shuffled quintic")
  public init() {}
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    for i in 0..<n {
      let x = (2.0 * Double(i) / Double(n)) - 1.0
      let v = pow(x, 5)
      let w = (v + 1.0) / 2.0 * Double(n) + 1.0
      engine.setValue(i, Int(w.rounded(.down)) + 1)
    }
    guard n > 1 else { return }
    for i in stride(from: n - 1, to: 0, by: -1) {
      let j = Int.random(in: 0...i)
      engine.swap(i, j)
    }
  }
}
