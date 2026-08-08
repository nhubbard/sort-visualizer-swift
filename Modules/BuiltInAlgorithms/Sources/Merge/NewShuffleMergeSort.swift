import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `NewShuffleMergeSort` — genuinely in-place merging via perfect-shuffle
/// permutations, based on the shuffle/unshuffle construction from Ellis & Markov's "In-place
/// associative computation" line of work (the class's own citations: the shuffle algorithm and its
/// time-complexity proof). `shuffle`/`unshuffle` interleave (or un-interleave) a range using
/// cycle-following over `i -> i*2 mod size`, glued together for arbitrary-length ranges via
/// `shuffleEasy`/`unshuffleEasy` blocks sized to the largest power of 3 that fits — `shuffleEasy`'s
/// `size` parameter is a cycle *modulus*, not an element count: it only ever touches the `size - 1`
/// real positions `start+1 ... start+size-1`, never `start+size` itself.
///
/// Reuses `RotateMergeSort`/`RotateLSDRadixSort`/`RotateMSDRadixSort`'s `rotate`/`multiSwap`
/// Gries-Mills block-rotation primitive verbatim for the "plain" rotations
/// (`rotate`/`rotateEqual`); `rotateShuffled*` are the same block-rotation shape but stepping by 2
/// (rotating already-shuffled interleaved pairs rather than plain elements).
///
/// Extends `IterativeTopDownMergeSort` in ArrayV purely to reuse its doubling-`subarrayCount`
/// driver loop with this file's own `merge` substituted in — this port keeps its own copy of that
/// driver rather than sharing a `Template` type with `IterativeTopDownMergeSort.swift`, the same
/// precedent the `i`/`b`/`q`/`m` radix family used (`StacklessBinaryQuickSort`/`RotateMSDRadixSort`):
/// only two real consumers exist, and this one genuinely overrides the interesting part rather than
/// purely delegating, so a shared enum wouldn't pull its weight. No aux buffer is needed here at
/// all (unlike the parent's own `merge`) since every move is either a swap or an in-place
/// permutation-cycle write.
///
/// Stability: not established. `mergeUp`'s `type` flag flips exactly when a shuffled run boundary
/// is crossed, which reads like deliberate stable-merge engineering, but confirming that by
/// inspection wasn't tractable in the time budgeted, and no valid empirical technique applies here
/// either (`rotate*` moves via `swap`, but `shuffleEasy`/`unshuffleEasy` move via `setValue` — a mix
/// the swap-tape-shadow technique this codebase's other stability tests rely on can't handle, the
/// same limitation `AmericanFlagSort`'s doc comment already explains). Left at the conservative
/// default rather than asserted either way.
public struct NewShuffleMergeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "newshufflemergesort")
  public let metadata = AlgorithmMetadata(
    displayName: "New Shuffle Merge Sort",
    category: .merge,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 818, coefficients: [228622, 411.74, 0.115292],
      measuredSafeCeiling: nil),
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(1)",
    iconName: "shuffle"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n >= 2 else { return }

    func multiSwap(_ a: Int, _ b: Int, _ len: Int) {
      for i in 0..<len { engine.swap(a + i, b + i) }
    }

    func rotate(_ midIn: Int, _ aIn: Int, _ bIn: Int) {
      var mid = midIn
      var a = aIn
      var b = bIn
      while a > 0 && b > 0 {
        if a > b {
          multiSwap(mid - b, mid, b)
          mid -= b
          a -= b
        } else {
          multiSwap(mid - a, mid, a)
          mid += a
          b -= a
        }
      }
    }

    func shuffleEasy(_ start: Int, _ size: Int) {
      var i = 1
      while i < size {
        var val = engine.values[start + i - 1]
        var j = i * 2 % size
        while j != i {
          let nval = engine.values[start + j - 1]
          engine.setValue(start + j - 1, val)
          val = nval
          j = j * 2 % size
        }
        engine.setValue(start + i - 1, val)
        i *= 3
      }
    }

    func shuffle(_ startIn: Int, _ end: Int) {
      var start = startIn
      while end - start > 1 {
        let half = (end - start) / 2
        var l = 1
        while l * 3 - 1 <= 2 * half { l *= 3 }
        let m = (l - 1) / 2

        rotate(start + half, half - m, m)
        shuffleEasy(start, l)
        start += l - 1
      }
    }

    func rotateShuffledEqual(_ a: Int, _ b: Int, _ size: Int) {
      var i = 0
      while i < size {
        engine.swap(a + i, b + i)
        i += 2
      }
    }

    func rotateShuffled(_ midIn: Int, _ aIn: Int, _ bIn: Int) {
      var mid = midIn
      var a = aIn
      var b = bIn
      while a > 0 && b > 0 {
        if a > b {
          rotateShuffledEqual(mid - b, mid, b)
          mid -= b
          a -= b
        } else {
          rotateShuffledEqual(mid - a, mid, a)
          mid += a
          b -= a
        }
      }
    }

    func rotateShuffledOuter(_ midIn: Int, _ aIn: Int, _ bIn: Int) {
      var mid = midIn
      var a = aIn
      var b = bIn
      if a > b {
        rotateShuffledEqual(mid - b, mid + 1, b)
        mid -= b
        a -= b
        rotateShuffled(mid, a, b)
      } else {
        rotateShuffledEqual(mid - a, mid + 1, a)
        mid += a + 1
        b -= a
        rotateShuffled(mid, a, b)
      }
    }

    func unshuffleEasy(_ start: Int, _ size: Int) {
      var i = 1
      while i < size {
        var prev = i
        let val = engine.values[start + i - 1]
        var j = i * 2 % size
        while j != i {
          engine.setValue(start + prev - 1, engine.values[start + j - 1])
          prev = j
          j = j * 2 % size
        }
        engine.setValue(start + prev - 1, val)
        i *= 3
      }
    }

    func unshuffle(_ startIn: Int, _ end: Int) {
      var start = startIn
      while end - start > 1 {
        let half = (end - start) / 2
        var l = 1
        while l * 3 - 1 <= 2 * half { l *= 3 }
        let m = (l - 1) / 2

        rotateShuffledOuter(start + 2 * m, 2 * m, 2 * half - 2 * m)
        unshuffleEasy(start, l)
        start += l - 1
      }
    }

    // Tri-state compare, matching ArrayV's `Reads.compareIndices`: -1 (less), 0 (equal), 1
    // (greater). Records exactly one comparison op, inferring equality from the values already
    // read rather than issuing a second one.
    func compare3(_ i: Int, _ j: Int) -> Int {
      if engine.compare(i, j, by: (<)) { return -1 }
      return engine.values[i] == engine.values[j] ? 0 : 1
    }

    func mergeUp(_ start: Int, _ end: Int, _ typeIn: Bool) {
      var i = start
      var j = i + 1
      var type = typeIn
      while j < end {
        let cmp = compare3(i, j)
        if cmp == -1 || (!type && cmp == 0) {
          i += 1
          if i == j {
            j += 1
            type.toggle()
          }
        } else if end - j == 1 {
          rotate(j, j - i, 1)
          break
        } else {
          var r = 0
          if type {
            while j + 2 * r < end, compare3(j + 2 * r, i) != 1 { r += 1 }
          } else {
            while j + 2 * r < end, compare3(j + 2 * r, i) == -1 { r += 1 }
          }
          j -= 1
          unshuffle(j, j + 2 * r)
          rotate(j, j - i, r)
          i += r + 1
          j += 2 * r + 1
        }
      }
    }

    func merge(_ start: Int, _ mid: Int, _ end: Int) {
      if mid - start <= end - mid {
        shuffle(start, end)
        mergeUp(start, end, true)
      } else {
        shuffle(start + 1, end)
        mergeUp(start, end, false)
      }
    }

    func ceilPowerOfTwo(_ x: Int) -> Int {
      var x = x - 1
      var i = 16
      while i > 0 {
        x |= x >> i
        i >>= 1
      }
      return x + 1
    }

    var subarrayCount = ceilPowerOfTwo(n)
    while subarrayCount > 1 {
      var i = 0
      while i < subarrayCount {
        merge(n * i / subarrayCount, n * (i + 1) / subarrayCount, n * (i + 2) / subarrayCount)
        i += 2
      }
      subarrayCount >>= 1
    }
  }
}
