import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `BogoBogoSort` — Bogosort's "is it sorted?" check replaced by a joke: to
/// decide whether a range is sorted, copy it, `BogoBogoSort` the copy's prefix (recursively — the
/// same joke one level down), reshuffle-and-retry until the copy's last two elements land in
/// order, then diff the copy against the original. `bogoBogoIsSorted(range, length)` is therefore
/// functionally just `isSorted(range)` — it only *computes* that answer through an absurdly
/// expensive recursive detour, which is the entire point of this being filed under "Impractical
/// Sorts" (ArrayV's own `setCategory` call, despite living in `sorts/distribute/` — see
/// Documentation/docs/guides/adding-an-algorithm.md's note that category always comes from that call, not the
/// directory).
///
/// One buffer per recursion depth (`tmp[idx]` backs depth `idx + 2`, sizes `2...n`, mirroring
/// ArrayV's own preallocated `tmp` array) is reused across every call at that depth — the
/// recursion is only `n` levels deep, not exponentially many buffers, so replacing ArrayV's
/// `Random`-based `bogoSwap` with a deterministic walk doesn't need any state shared *across*
/// depths. Two different techniques already proven safe elsewhere in this codebase handle the
/// *two* reshuffle sites this algorithm has, because they have different interleaving shapes:
///
/// - The outer `bogoBogo` retry loop reshuffles a range that nothing else touches between
///   attempts (the recursive check underneath it only ever reads that range, writing exclusively
///   to a separate, deeper scratch buffer) — safe to reuse `BogoSort`'s plain lexicographic
///   `next_permutation` walk verbatim.
/// - The inner tail-fixup loop (retry until the last two elements of the *copy* are in order)
///   reshuffles the *whole* copy while a nested recursive call re-sorts just its prefix between
///   attempts — the exact interleaving shape `SmartBogoBogoSort`'s doc comment already proved
///   breaks `next_permutation` (it can strand the walk in a real 2-cycle) and fixed by swapping
///   the next never-yet-tried candidate into the last slot instead, with a hard
///   `length - 1`-attempt ceiling. Applied unchanged here, once per recursion depth.
///
/// Every comparison/swap the *outermost* check performs against the real array is real engine
/// traffic; everything the recursion touches below the first `tmp` copy is local bookkeeping
/// mirrored into that depth's aux array via `writeAux`, the same convention `MSDRadixSort`'s
/// bucket lists and `AmericanFlagSort`'s count/offset arrays already use for scratch structures
/// that aren't the main array itself.
public struct BogoBogoSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "bogobogosort")
  public let metadata = AlgorithmMetadata(
    displayName: "Bogo Bogo Sort",
    category: .impractical,
    sizeRange: 3...5,
    growthModel: OperationGrowthModel(
      anchorSize: 5, coefficients: [13144.9, 49865.6, 97681.7, 131149, 135324, 114176],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .factorial, coefficients: [9.98816, 2.35705], rSquared: 0.458102),
    implementationComplexity: 35,
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n)", average: "O(n \\times n!^2)", worst: "O(n \\times n!^2)"),
    spaceComplexity: "O(n^2)",
    iconName: "die.face.6.fill"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    // `tmp[idx]` backs recursion depth `idx + 2`.
    var tmp: [[Int]] = (0...(n - 2)).map { [Int](repeating: 0, count: $0 + 2) }
    let tmpHandles: [AuxHandle] = tmp.map { engine.createAuxArray(length: $0.count) }

    func writeTmp(_ idx: Int, _ i: Int, _ value: Int) {
      tmp[idx][i] = value
      engine.writeAux(tmpHandles[idx], at: i, value: value)
    }

    func reverseTmp(_ idx: Int, _ length: Int) {
      var lo = 0
      var hi = length - 1
      while lo < hi {
        let a = tmp[idx][lo]
        let b = tmp[idx][hi]
        writeTmp(idx, lo, b)
        writeTmp(idx, hi, a)
        lo += 1
        hi -= 1
      }
    }

    // Deterministic lexicographic next_permutation over `tmp[idx][0..<length)`, exactly
    // `BogoSort`'s technique. Returns `false` once `tmp[idx]` is the fully-descending
    // permutation — the caller reverses to wrap to the sorted one, same as `BogoSort`.
    @discardableResult
    func advancePermutation(_ idx: Int, _ length: Int) -> Bool {
      var i = length - 2
      while i >= 0 && tmp[idx][i] >= tmp[idx][i + 1] { i -= 1 }
      guard i >= 0 else { return false }
      var j = length - 1
      while tmp[idx][j] <= tmp[idx][i] { j -= 1 }
      let vi = tmp[idx][i]
      let vj = tmp[idx][j]
      writeTmp(idx, i, vj)
      writeTmp(idx, j, vi)
      var lo = i + 1
      var hi = length - 1
      while lo < hi {
        let a = tmp[idx][lo]
        let b = tmp[idx][hi]
        writeTmp(idx, lo, b)
        writeTmp(idx, hi, a)
        lo += 1
        hi -= 1
      }
      return true
    }

    // `bogoBogoIsSorted(tmp[sourceIdx], length)`: functionally `isSorted`, computed by copying
    // into the scratch buffer for depth `length`, recursively `bogoBogo`-sorting its prefix,
    // fixing up the tail via `SmartBogoBogoSort`'s candidate technique, then diffing.
    func localBogoBogoIsSorted(_ sourceIdx: Int, _ length: Int) -> Bool {
      if length == 1 { return true }
      let deeperIdx = length - 2
      for i in 0..<length { writeTmp(deeperIdx, i, tmp[sourceIdx][i]) }
      localBogoBogo(deeperIdx, length - 1)

      var candidate = 0
      while tmp[deeperIdx][length - 2] > tmp[deeperIdx][length - 1] {
        let a = tmp[deeperIdx][candidate]
        let b = tmp[deeperIdx][length - 1]
        writeTmp(deeperIdx, candidate, b)
        writeTmp(deeperIdx, length - 1, a)
        candidate += 1
        localBogoBogo(deeperIdx, length - 1)
      }

      for i in 0..<length where tmp[sourceIdx][i] != tmp[deeperIdx][i] { return false }
      return true
    }

    func localBogoBogo(_ idx: Int, _ length: Int) {
      while !localBogoBogoIsSorted(idx, length) {
        if !advancePermutation(idx, length) {
          reverseTmp(idx, length)
        }
      }
    }

    // `bogoBogoIsSorted(array, n)` against the real engine array — same shape as
    // `localBogoBogoIsSorted`, but reading the main array (via `engine.values`, no
    // aux-mirroring needed) instead of a shallower `tmp` buffer.
    func topIsSorted() -> Bool {
      let idx = n - 2
      for i in 0..<n { writeTmp(idx, i, engine.values[i]) }
      localBogoBogo(idx, n - 1)

      var candidate = 0
      while tmp[idx][n - 2] > tmp[idx][n - 1] {
        let a = tmp[idx][candidate]
        let b = tmp[idx][n - 1]
        writeTmp(idx, candidate, b)
        writeTmp(idx, n - 1, a)
        candidate += 1
        localBogoBogo(idx, n - 1)
      }

      for i in 0..<n where engine.values[i] != tmp[idx][i] { return false }
      return true
    }

    // `BogoSort`'s own next_permutation walk, applied to the real engine array.
    @discardableResult
    func advanceMainPermutation() -> Bool {
      var i = n - 2
      while i >= 0, engine.compare(i, i + 1) { i -= 1 }
      guard i >= 0 else { return false }
      var j = n - 1
      while !engine.compare(j, i, by: (>)) { j -= 1 }
      engine.swap(i, j)
      engine.reversal(i + 1, n - 1)
      return true
    }

    while !topIsSorted() {
      if !advanceMainPermutation() {
        engine.reversal(0, n - 1)
      }
    }

    for handle in tmpHandles { engine.deleteAuxArray(handle) }
  }
}
