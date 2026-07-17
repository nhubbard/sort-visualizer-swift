import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `Shuffles.BLOCK_RANDOMLY`. Picks the largest power of two at or below
/// `sqrt(n)` as a block size, then randomly swaps whole blocks of that size with each other —
/// a coarser-grained cousin of a plain Fisher-Yates shuffle that preserves each block's own
/// internal order while scrambling block positions.
public struct BlockRandomShuffle: ShuffleAlgorithm {
  public let id = ShuffleID(rawValue: "blockrandomly")
  public let metadata = ShuffleMetadata(displayName: "Randomly w/ Blocks")
  public init() {}

  private func greatestPowerOfTwoAtOrBelow(_ value: Int) -> Int {
    var v = 1
    while v <= value { v <<= 1 }
    return v >> 1
  }

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 0 else { return }
    let blockSize = greatestPowerOfTwoAtOrBelow(Int(Double(n).squareRoot()))
    guard blockSize > 0 else { return }
    let usableLength = n - n % blockSize

    var i = 0
    while i < usableLength {
      let randomIndex = Int.random(in: 0..<((usableLength - i) / blockSize)) * blockSize + i
      for offset in 0..<blockSize {
        engine.swap(i + offset, randomIndex + offset)
      }
      i += blockSize
    }
  }
}
