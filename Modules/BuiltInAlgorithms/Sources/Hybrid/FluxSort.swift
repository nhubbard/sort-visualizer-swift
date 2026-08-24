import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `FluxSort` — Igor van den Hoven's real `fluxsort.c` (via ArrayV's Java
/// re-implementation, itself ported by mg-2018/aphitorite). A dual-pivot-free quicksort/mergesort
/// hybrid: `fluxAnalyze` scans once for existing order (already sorted, fully reversed, or
/// mostly-sorted/-reversed enough that a plain `QuadSortingTemplate.sort` beats partitioning
/// outright), then `fluxPartition` recursively splits around a median-of-9/15 pivot, bottoming out
/// into `QuadSortingTemplate.sort(_:using:start:length:)` (ArrayV's `quadSortSwap`) once a side is
/// small or skewed enough.
///
/// `fluxPartition` ping-pongs its *read* source between the live array and one shared scratch
/// buffer (`swap`, sized to the top-level `nmemb` and allocated once in `record(into:)`) without
/// ArrayV's `main == array` reference-identity check, which has no Swift equivalent for a `struct`
/// buffer — `mainIsSwap` replaces it explicitly. Every recursive call only ever needs a 0-based
/// scratch window no larger than its own `nmemb`/2-ish (confirmed against `QuadSortingTemplate`'s
/// `tailMerge`/`quadMerge`, which never address `aux` past that), and recursion is strictly
/// depth-first/sequential — the "high" side's whole subtree completes (and stops touching `swap`)
/// before the "low" side's subtree starts — so reusing one flat buffer's front portion at every
/// depth is safe, never overlapping a still-live use.
///
/// Two systematic translation decisions, both already established by `QuadSortingTemplate`'s own
/// doc comment: `Reads.compareIndices` on real main-array positions becomes `engine.compare(_:_:
/// by:)` (real, visualized); comparisons that ArrayV performs on `main` when `main` is the *swap*
/// buffer become bare Swift value comparisons with no engine call (an aux-buffer index has no
/// sensible marker position, matching e.g. `WeavedMergeSort`'s precedent). `mainGT` below picks
/// between the two per call, based on `mainIsSwap`. Decorative `Highlights.markArray`/`clearMark`
/// calls (partition-loop and median-selection highlighting) are dropped, matching every other
/// merge/quad-family port in this codebase.
///
/// `stable: true`, matching upstream `scandum/fluxsort`'s own documented guarantee — asserted by
/// construction, the same way `QuadSort`'s own doc comment argues its claim, not by the swap-tape-
/// shadow-replay fuzz test (`NativeAlgorithmCorrectnessTests.expectStable`): that technique only
/// holds when every real mutation is a swap, and both `fluxPartition` and the `QuadSortingTemplate`
/// base case it bottoms out into move data mostly via `engine.setValue`. Two steps close the proof:
/// - **One partition step preserves relative order within each output group.** The loop reads
///   `main` strictly left-to-right (`ptx` only increments) and every element goes to exactly one
///   of two forward-only write cursors (`pta` into the array, `pts` into `swap`) chosen by `value >
///   piv` — never `>=` — so an element equal to the pivot always lands on the "low" (array) side.
///   Since each destination is filled by its own single increasing cursor, whichever group an
///   element ends up in, it arrives in the same relative order it was read in.
/// - **Composing a stable partition with two independently-stable-sorted groups is stable.** A
///   tie (equal values) can only occur *within* one group — the partition step above already
///   proved membership is order-preserving, and value equality forces both tied elements to the
///   same side of `value > piv`, so they're always in the same group, never split across the
///   low/high boundary. Each group is then finished either by recursing into `fluxPartition` again
///   (stable by induction on this same argument) or by `QuadSortingTemplate.sort(using:)`, already
///   proven stable by construction in `QuadSort.swift`'s own doc comment. No tie ever needs to be
///   resolved *across* the low/high boundary, so the two groups' independent stability is enough
///   for the whole recursion to be stable.
public struct FluxSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "fluxsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Flux",
    category: .hybrid,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 1898, coefficients: [193845, 157.794, 0.0221831],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [0.601011, 1.41254], rSquared: 0.75106),
    stable: true,
    // fluxsort is documented worst-case O(n log n), unlike a plain median-of-one quicksort — the
    // fluxAnalyze early-outs and the FLUX_OUT/ratio guards against a degenerate partition keep it
    // out of quicksort's usual O(n^2) worst case.
    timeComplexity: ComplexityBounds(
      best: "O(n)", average: "O(n log n)", worst: "O(n log n)"),
    // One full-size scratch buffer, shared across every recursion depth (see the type doc above).
    spaceComplexity: "O(n)",
    iconName: "bolt.fill"
  )

  public init() {}

  /// Below this size, `fluxPartition` bottoms out into `quadSortSwap` outright rather than
  /// recursing again — matches ArrayV's `FLUX_OUT`.
  private static let fluxOut = 24

  public func record(into engine: inout RecordingEngine) {
    let nmemb = engine.count
    guard nmemb > 1 else { return }

    if nmemb < 32 {
      QuadSortingTemplate.sort(&engine, start: 0, length: nmemb)
      return
    }

    guard Self.fluxAnalyze(&engine, nmemb: nmemb) else { return }

    let handle = engine.createAuxArray(length: nmemb)
    var swap = AuxBuffer(handle: handle, length: nmemb)
    Self.fluxPartition(&engine, &swap, mainIsSwap: false, start: 0, nmemb: nmemb)
    engine.deleteAuxArray(handle)
  }

  /// One adjacent-pair scan counting inversions (`balance`). Returns `false` whenever the array
  /// was fully handled without partitioning: already sorted, fully reverse-sorted (one
  /// `engine.reversal` away from sorted), or mostly-sorted-or-reversed enough (`balance` within
  /// 1/6 of either end) that a plain `QuadSortingTemplate.sort` wins outright. Returns `true` only
  /// when real partitioning in `fluxPartition` is worthwhile.
  private static func fluxAnalyze(_ engine: inout RecordingEngine, nmemb: Int) -> Bool {
    var balance = 0
    var pta = 0
    var cnt = nmemb
    while true {
      cnt -= 1
      if cnt <= 0 { break }
      let left = pta
      pta += 1
      if engine.compare(left, pta, by: >) { balance += 1 }
    }

    if balance == 0 { return false }

    if balance == nmemb - 1 {
      engine.reversal(0, nmemb - 1)
      return false
    }

    if balance <= nmemb / 6 || balance >= nmemb / 6 * 5 {
      QuadSortingTemplate.sort(&engine, start: 0, length: nmemb)
      return false
    }

    return true
  }

  /// `1` if `main[a] > main[b]`, else `0` — the `(Reads.compareIndices(...)+1)/2` idiom every
  /// median-selection comparison below uses, simplified: that expression is exactly `a > b ? 1 :
  /// 0` once `compareIndices`' sign result is known. Branches on `mainIsSwap` per the type doc's
  /// aux-vs-main comparison rule.
  private static func mainGT(
    _ engine: inout RecordingEngine, _ swap: AuxBuffer, _ mainIsSwap: Bool, _ a: Int, _ b: Int
  ) -> Int {
    if mainIsSwap {
      return swap.values[a] > swap.values[b] ? 1 : 0
    }
    return engine.compare(a, b, by: >) ? 1 : 0
  }

  /// Median-of-3 index tournament — verbatim translation of ArrayV's `medianOfThree`, substituting
  /// `mainGT` for the `(compareIndices+1)/2`/`^1` idiom throughout.
  private static func medianOfThree(
    _ engine: inout RecordingEngine, _ swap: AuxBuffer, _ mainIsSwap: Bool,
    _ v0: Int, _ v1: Int, _ v2: Int
  ) -> Int {
    var val = mainGT(&engine, swap, mainIsSwap, v0, v1)
    var t0 = val
    var t1 = val ^ 1

    val = mainGT(&engine, swap, mainIsSwap, v0, v2)
    t0 += val
    if t0 == 1 { return v0 }

    val = mainGT(&engine, swap, mainIsSwap, v1, v2)
    t1 += val
    return t1 == 1 ? v1 : v2
  }

  /// Median-of-5 index tournament — verbatim translation of ArrayV's `medianOfFive`.
  private static func medianOfFive(
    _ engine: inout RecordingEngine, _ swap: AuxBuffer, _ mainIsSwap: Bool,
    _ v0: Int, _ v1: Int, _ v2: Int, _ v3: Int, _ v4: Int
  ) -> Int {
    var val = mainGT(&engine, swap, mainIsSwap, v0, v1)
    var t0 = val
    var t1 = val ^ 1

    val = mainGT(&engine, swap, mainIsSwap, v0, v2)
    t0 += val
    var t2 = val ^ 1

    val = mainGT(&engine, swap, mainIsSwap, v0, v3)
    t0 += val
    var t3 = val ^ 1

    val = mainGT(&engine, swap, mainIsSwap, v0, v4)
    t0 += val

    if t0 == 2 { return v0 }

    val = mainGT(&engine, swap, mainIsSwap, v1, v2)
    t1 += val
    t2 += val ^ 1

    val = mainGT(&engine, swap, mainIsSwap, v1, v3)
    t1 += val
    t3 += val ^ 1

    val = mainGT(&engine, swap, mainIsSwap, v1, v4)
    t1 += val

    if t1 == 2 { return v1 }

    val = mainGT(&engine, swap, mainIsSwap, v2, v3)
    t2 += val
    t3 += val ^ 1

    val = mainGT(&engine, swap, mainIsSwap, v2, v4)
    t2 += val

    if t2 == 2 { return v2 }

    val = mainGT(&engine, swap, mainIsSwap, v3, v4)
    t3 += val

    return t3 == 2 ? v3 : v4
  }

  /// Picks a pivot from 9 evenly-spaced samples via 3 median-of-3s feeding one more — used when
  /// the partition being pivoted is at most 1024 elements.
  private static func medianOfNine(
    _ engine: inout RecordingEngine, _ swap: AuxBuffer, _ mainIsSwap: Bool, _ ptx: Int, _ nmemb: Int
  ) -> Int {
    let div = nmemb / 16
    let v0 = medianOfThree(&engine, swap, mainIsSwap, ptx + div * 2, ptx + div * 1, ptx + div * 4)
    let v1 = medianOfThree(&engine, swap, mainIsSwap, ptx + div * 8, ptx + div * 6, ptx + div * 10)
    let v2 = medianOfThree(&engine, swap, mainIsSwap, ptx + div * 14, ptx + div * 12, ptx + div * 15)
    return medianOfThree(&engine, swap, mainIsSwap, v0, v1, v2)
  }

  /// Picks a pivot from 15 evenly-spaced samples via 5 median-of-3s feeding one median-of-5 — used
  /// once the partition being pivoted exceeds 1024 elements.
  private static func medianOfFifteen(
    _ engine: inout RecordingEngine, _ swap: AuxBuffer, _ mainIsSwap: Bool, _ ptx: Int, _ nmemb: Int
  ) -> Int {
    let div = nmemb / 16
    let v0 = medianOfThree(&engine, swap, mainIsSwap, ptx + div * 2, ptx + div * 1, ptx + div * 3)
    let v1 = medianOfThree(&engine, swap, mainIsSwap, ptx + div * 5, ptx + div * 4, ptx + div * 6)
    let v2 = medianOfThree(&engine, swap, mainIsSwap, ptx + div * 8, ptx + div * 7, ptx + div * 9)
    let v3 = medianOfThree(&engine, swap, mainIsSwap, ptx + div * 11, ptx + div * 10, ptx + div * 12)
    let v4 = medianOfThree(&engine, swap, mainIsSwap, ptx + div * 14, ptx + div * 13, ptx + div * 15)
    return medianOfFive(&engine, swap, mainIsSwap, v2, v0, v1, v3, v4)
  }

  /// The core recursive partition. Reads `main` (the live array if `!mainIsSwap`, else `swap`)
  /// left to right starting at `mainIsSwap ? 0 : start`, picks a pivot via `medianOfNine`/
  /// `medianOfFifteen`, then for every element unconditionally writes it to *both* the array (at
  /// the forward cursor `pta`) and `swap` (at the forward cursor `pts`) — but only advances
  /// whichever cursor is that element's real destination (`value > piv` → `swap`/`pts`, else
  /// array/`pta`). This is fluxsort's branchless partition trick: the "wrong" write for an element
  /// is simply overwritten later by the next element that really belongs at that slot, so no
  /// conditional/branch is needed to pick a destination up front. Recurses into whichever side
  /// still needs it (skipping straight to `QuadSortingTemplate.sort(using:)` once a side is small
  /// or skewed enough), high side first — see the type doc for why that order, not just this
  /// call's own indices, is what keeps the shared `swap` buffer's reuse safe.
  private static func fluxPartition(
    _ engine: inout RecordingEngine, _ swap: inout AuxBuffer, mainIsSwap: Bool, start: Int,
    nmemb: Int
  ) {
    let ptxBase = mainIsSwap ? 0 : start
    let medianIndex =
      nmemb > 1024
      ? medianOfFifteen(&engine, swap, mainIsSwap, ptxBase, nmemb)
      : medianOfNine(&engine, swap, mainIsSwap, ptxBase, nmemb)
    let piv = mainIsSwap ? swap.values[medianIndex] : engine.values[medianIndex]

    let pte = ptxBase + nmemb
    var pta = start
    var pts = 0
    var ptx = ptxBase

    while ptx < pte {
      let value = mainIsSwap ? swap.values[ptx] : engine.values[ptx]
      let val = value > piv ? 1 : 0

      engine.setValue(pta, value)
      pta += 1 - val

      swap.write(&engine, at: pts, value: value)
      pts += val

      ptx += 1
    }

    let sSize = pts
    let aSize = nmemb - sSize

    if aSize <= sSize / 16 || sSize <= fluxOut {
      for i in 0..<sSize {
        engine.setValue(pta + i, swap.values[i])
      }
      QuadSortingTemplate.sort(&engine, using: &swap, start: pta, length: sSize)
    } else {
      fluxPartition(&engine, &swap, mainIsSwap: true, start: pta, nmemb: sSize)
    }

    if sSize <= aSize / 16 || aSize <= fluxOut {
      QuadSortingTemplate.sort(&engine, using: &swap, start: start, length: aSize)
    } else {
      fluxPartition(&engine, &swap, mainIsSwap: false, start: start, nmemb: aSize)
    }
  }
}
