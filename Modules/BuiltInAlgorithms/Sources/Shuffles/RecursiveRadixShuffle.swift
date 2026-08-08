import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `Shuffles.REC_RADIX`. Recursively un-weaves the array: at each level, saves
/// the first half of the current (`gap`-strided) range, interleaves the second half back into it,
/// then recurses into each of the two resulting `gap`-doubled sub-ranges — the recursive analogue
/// of `FinalRadixShuffle`'s single-level un-interleave, applied at every radix-sort pass rather than
/// just the last one.
public struct RecursiveRadixShuffle: ShuffleAlgorithm {
  public let id = ShuffleID(rawValue: "recradix")
  public let metadata = ShuffleMetadata(displayName: "Recursive Final Radix")
  public init() {}
  public func record(into engine: inout RecordingEngine) {
    weaveRec(&engine, pos: 0, length: engine.count, gap: 1)
  }

  private func weaveRec(_ engine: inout RecordingEngine, pos: Int, length: Int, gap: Int) {
    guard length >= 2 else { return }
    let mod2 = length % 2
    let evenLength = length - mod2
    let mid = evenLength / 2

    var temp = [Int](repeating: 0, count: mid)
    var i = pos
    var j = 0
    while i < pos + gap * mid {
      temp[j] = engine.values[i]
      i += gap
      j += 1
    }

    i = pos + gap * mid
    var k = 0
    j = pos
    while i < pos + gap * evenLength {
      engine.setValue(j, engine.values[i])
      engine.setValue(j + gap, temp[k])
      i += gap
      j += 2 * gap
      k += 1
    }

    weaveRec(&engine, pos: pos, length: mid + mod2, gap: 2 * gap)
    weaveRec(&engine, pos: pos + gap, length: mid, gap: 2 * gap)
  }
}
