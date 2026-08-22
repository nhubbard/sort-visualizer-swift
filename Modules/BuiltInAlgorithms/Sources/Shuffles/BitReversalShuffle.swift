import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `Shuffles.BIT_REVERSE`. Builds the classic bit-reversal permutation over
/// the largest power-of-two prefix `len <= n` (each index's bits read back-to-front), then — for a
/// non-power-of-two `n` — extends it across the remaining `n - len` indices via a stable counting
/// sort so every index still ends up with a distinct target. Computes that whole permutation in a
/// local Swift array first, then gathers the original values through it in one pass, following the
/// same convention as `BSTTraversalShuffle`/`RealFinalRadixShuffle` rather than ArrayV's literal
/// scratch-array-with-recorded-swaps approach.
///
/// `len` is found via the same doubling loop `BlockRandomShuffle.swift`'s
/// `greatestPowerOfTwoAtOrBelow` uses, not ArrayV's `1 << (int)(Math.log(n)/Math.log(2))` —
/// floating-point `log`'s rounding error can push an exact power of two's `log(n)/log(2)` a hair
/// below its true integer value, silently halving `len` right at a boundary (the same failure mode
/// `PoplarHeapSort.swift`'s `hyperfloor` doc comment already flags). The doubling loop can't have
/// that failure mode.
public struct BitReversalShuffle: ShuffleAlgorithm {
  public let id = ShuffleID(rawValue: "bitreverse")
  public let metadata = ShuffleMetadata(displayName: "Bit Reversal")
  public init() {}

  private func greatestPowerOfTwoAtOrBelow(_ value: Int) -> Int {
    var v = 1
    while v <= value { v <<= 1 }
    return v >> 1
  }

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 0 else { return }

    let len = greatestPowerOfTwoAtOrBelow(n)
    let pow2 = len == n

    var arr = [Int](repeating: 0, count: n)
    for i in 0..<len { arr[i] = i }

    let d1 = len >> 1
    let d2 = d1 + (d1 >> 1)
    var m = 0
    let upper = len - 1
    if upper > 1 {
      for i in 1..<upper {
        var j = d1
        var k = i
        var step = d2
        while (k & 1) == 0 {
          j -= step
          k >>= 1
          step >>= 1
        }
        m += j
        if m > i {
          arr.swapAt(i, m)
        }
      }
    }

    if !pow2 {
      for i in len..<n {
        arr[i] = arr[i - len]
      }

      var cnt = [Int](repeating: 0, count: len)
      for i in 0..<n {
        cnt[arr[i]] += 1
      }
      for i in 1..<cnt.count {
        cnt[i] += cnt[i - 1]
      }
      for i in stride(from: n - 1, through: 0, by: -1) {
        let key = arr[i]
        cnt[key] -= 1
        arr[i] = cnt[key]
      }
    }

    let original = engine.values
    for i in 0..<n {
      engine.setValue(i, original[arr[i]])
    }
  }
}
