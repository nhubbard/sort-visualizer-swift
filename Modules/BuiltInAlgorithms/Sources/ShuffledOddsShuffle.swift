import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `Shuffles.SHUFFLED_ODDS`. Every odd position swaps with a random *other*
/// odd position at or past it — `(random(n - i) / 2) * 2 + i` is always odd-offset-from-`i`, since
/// halving then doubling a random offset forces it to land on the same parity `i` already has.
public struct ShuffledOddsShuffle: ShuffleAlgorithm {
  public let id = ShuffleID(rawValue: "shuffledodds")
  public let metadata = ShuffleMetadata(displayName: "Scrambled Odds")
  public init() {}
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    var i = 1
    while i < n {
      let randomIndex = (Int.random(in: 0..<(n - i)) / 2) * 2 + i
      engine.swap(i, randomIndex)
      i += 2
    }
  }
}
