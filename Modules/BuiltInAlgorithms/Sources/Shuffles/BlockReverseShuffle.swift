import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `Shuffles.BLOCK_REVERSE`. Sibling of `BlockRandomShuffle`
/// (`Shuffles.BLOCK_RANDOMLY`) — same block size (the largest power of two `<= sqrt(n)`) and same
/// per-block swap shape, but mirrors blocks from both ends toward the middle instead of picking a
/// random partner for each.
public struct BlockReverseShuffle: ShuffleAlgorithm {
  public let id = ShuffleID(rawValue: "blockreverse")
  public let metadata = ShuffleMetadata(displayName: "Block Reverse")
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
    var j = usableLength - blockSize
    while i < j {
      for offset in 0..<blockSize {
        engine.swap(i + offset, j + offset)
      }
      i += blockSize
      j -= blockSize
    }
  }
}
