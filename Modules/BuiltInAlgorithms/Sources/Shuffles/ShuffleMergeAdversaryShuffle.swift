import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `Shuffles.SHUF_MERGE_BAD`. A self-contained adversarial arrangement
/// targeting bottom-up merge sort's worst case: at each doubling merge-width `d` (2, 4, 8, ... up
/// to the next power of two `>= n`), splits the array into runs of roughly `d` elements each (using
/// the same Bresenham-style even-distribution walk `FinalMergeShuffle`'s sibling ports use
/// elsewhere) and, within the centered window of each run, deinterleaves odds-then-evens — the
/// pattern that forces a merge at that width to do maximal interleaving work.
///
/// `shuffleBad`'s scratch buffer is a plain local Swift array read via `engine.values`/written back
/// via `engine.setValue`, not a recorded aux array — same convention as `FinalMergeShuffle`'s
/// `temp`.
public struct ShuffleMergeAdversaryShuffle: ShuffleAlgorithm {
  public let id = ShuffleID(rawValue: "shufmergebad")
  public let metadata = ShuffleMetadata(displayName: "Shuffle Merge Adversary")
  public init() {}

  private func nextPowerOfTwoAtOrAbove(_ value: Int) -> Int {
    var v = 1
    while v < value { v <<= 1 }
    return v
  }

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    var tmp = [Int](repeating: 0, count: n)
    let end = nextPowerOfTwoAtOrAbove(n)
    var d = 2

    while d <= end {
      var i = 0
      var dec = 0

      while i < n {
        var j = i
        dec += n
        while dec >= d {
          dec -= d
          j += 1
        }
        var k = j
        dec += n
        while dec >= d {
          dec -= d
          k += 1
        }
        shuffleMergeBad(&engine, &tmp, i, j, k)
        i = k
      }
      d *= 2
    }
  }

  private func shuffleMergeBad(
    _ engine: inout RecordingEngine, _ tmp: inout [Int], _ aIn: Int, _ m: Int, _ bIn: Int
  ) {
    var a = aIn
    var b = bIn
    if (b - a) % 2 == 1 {
      if m - a > b - m {
        a += 1
      } else {
        b -= 1
      }
    }
    shuffleBad(&engine, &tmp, a, b)
  }

  private func shuffleBad(_ engine: inout RecordingEngine, _ tmp: inout [Int], _ a: Int, _ b: Int) {
    guard b - a >= 2 else { return }

    let m = (a + b) / 2
    let s = (b - a - 1) / 4 + 1
    let windowStart = m - s
    let windowEnd = m + s

    var j = windowStart
    var i = windowStart + 1
    while i < windowEnd {
      tmp[j] = engine.values[i]
      j += 1
      i += 2
    }
    i = windowStart
    while i < windowEnd {
      tmp[j] = engine.values[i]
      j += 1
      i += 2
    }

    for pos in windowStart..<windowEnd {
      engine.setValue(pos, tmp[pos])
    }
  }
}
