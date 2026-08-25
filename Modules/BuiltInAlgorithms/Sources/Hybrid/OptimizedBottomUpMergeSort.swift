import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `OptimizedBottomUpMergeSort` — Sartaj Sahni's iterative merge sort
/// (explicitly modeled on `std::stable_sort`), with two structural differences from the
/// already-shipped `BottomUpMergeSort`:
/// - A binary-insertion pre-pass sorts the array in fixed 16-element blocks first (via ArrayV's
///   `BinaryInsertionSorting.binaryInsertSort` template method), so the doubling merge phase
///   starts from 16-element runs instead of the usual single-element ones.
/// - The merge phase genuinely ping-pongs between the live array and one scratch buffer —
///   `mergePass` alternates which buffer is the read side every call — rather than always
///   merging into scratch and copying back every pass the way `BottomUpMergeSort` does. This
///   halves the total write volume at the cost of needing every merge primitive in dual-direction
///   form, translated below via an explicit `fromMain` flag (same shape as `FluxSort`'s
///   `mainIsSwap`): reads/compares against a live main-array position become real
///   `engine.compare`/`engine.values`; reads/compares against the aux buffer become bare,
///   uncounted comparisons, since an aux position has no sensible marker to attach to.
///
/// **Real bug fixed, not reproduced**: ArrayV's own `n < 16` base case calls
/// `customBinaryInsert(a, 0, 16, ...)` — a hardcoded `16` upper bound, not `n`. That reads/writes
/// past the end of any array shorter than 16 elements. This port uses `n` instead, since this
/// app's `RecordingEngine` genuinely holds an array of exactly `n` elements (no over-allocated
/// backing store the original might have relied on) and this codebase's own correctness suite
/// fuzzes sizes well below 16.
///
/// `stable: true` — matches the upstream `std::stable_sort` naming exactly, and both real
/// tie-breaking rules confirm it: the pre-pass's binary search moves an inserted element to
/// `lo` only past *smaller* values (a held value compared with `<`, never `<=`, so an equal
/// existing element is never skipped past); every merge favors the left run on a tie
/// (`<=`). Every write throughout is `setValue`/aux-write, never a swap, so the usual swap-tape-
/// shadow-replay empirical check (`NativeAlgorithmCorrectnessTests.expectStable`) doesn't apply
/// here either — this is a by-construction argument, the same rigor tier as `QuadSort`'s own.
public struct OptimizedBottomUpMergeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "optimizedbottomupmergesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Optimized Bottom-Up Merge",
    category: .hybrid,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 2618, coefficients: [239895, 173.45, 0.031255],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [0.031255, 9.79871, 22.3343], rSquared: 0.998999),
    stable: true,
    // No data-dependent short-circuit anywhere — the doubling merge structure runs the same
    // shape of passes regardless of input order.
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(n)",
    iconName: "rectangle.stack.fill"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    // ArrayV's `BinaryInsertionSorting.binaryInsertSort`: `num` is captured once per outer
    // iteration and reused across the whole binary search and shift, so every comparison here
    // is bare (Rule B) — never a real `engine.compare`. The shift itself moves elements via
    // `setValue`, not swaps (`Writes.write(array, j + 1, array[j], ...)` in the original).
    func binaryInsert(_ start: Int, _ end: Int) {
      guard start < end else { return }
      for i in start..<end {
        let num = engine.values[i]
        var lo = start
        var hi = i
        while lo < hi {
          let mid = lo + (hi - lo) / 2
          if num < engine.values[mid] {
            hi = mid
          } else {
            lo = mid + 1
          }
        }
        var j = i - 1
        while j >= lo {
          engine.setValue(j + 1, engine.values[j])
          j -= 1
        }
        engine.setValue(lo, num)
      }
    }

    // Merges `[lt, md]` and `[md+1, rt]` — reading from the live array and writing into `aux`
    // when `fromMain` is true, or the reverse when false. `lessOrEqual`/`sourceValue` pick the
    // right primitive per direction; ties favor the left run (`i`), which is what keeps this
    // stable.
    func merge(_ aux: inout AuxBuffer, fromMain: Bool, _ lt: Int, _ md: Int, _ rt: Int) {
      func sourceValue(_ index: Int) -> Int { fromMain ? engine.values[index] : aux.values[index] }
      func writeDest(_ index: Int, _ value: Int) {
        if fromMain {
          aux.write(&engine, at: index, value: value)
        } else {
          engine.setValue(index, value)
        }
      }
      func lessOrEqual(_ a: Int, _ b: Int) -> Bool {
        fromMain ? engine.compare(a, b, by: <=) : aux.values[a] <= aux.values[b]
      }

      var i = lt
      var j = md + 1
      var k = lt
      while i <= md && j <= rt {
        if lessOrEqual(i, j) {
          writeDest(k, sourceValue(i))
          i += 1
        } else {
          writeDest(k, sourceValue(j))
          j += 1
        }
        k += 1
      }
      while i <= md {
        writeDest(k, sourceValue(i))
        i += 1
        k += 1
      }
      while j <= rt {
        writeDest(k, sourceValue(j))
        j += 1
        k += 1
      }
    }

    // One pass merging every adjacent pair of `s`-sized runs; a final partial chunk either gets
    // one more merge (if it's smaller than a full run) or is just copied across untouched
    // (already exactly one sorted run, nothing to merge it with).
    func mergePass(_ aux: inout AuxBuffer, fromMain: Bool, _ s: Int, _ n: Int) {
      var i = 0
      while i <= n - 2 * s {
        merge(&aux, fromMain: fromMain, i, i + s - 1, i + 2 * s - 1)
        i += 2 * s
      }
      if i + s < n {
        merge(&aux, fromMain: fromMain, i, i + s - 1, n - 1)
      } else {
        for j in i..<n {
          let value = fromMain ? engine.values[j] : aux.values[j]
          if fromMain {
            aux.write(&engine, at: j, value: value)
          } else {
            engine.setValue(j, value)
          }
        }
      }
    }

    if n < 16 {
      binaryInsert(0, n)
      return
    }

    var i = 0
    while i <= n - 16 {
      binaryInsert(i, i + 16)
      i += 16
    }
    binaryInsert(i, n)

    let handle = engine.createAuxArray(length: n)
    var aux = AuxBuffer(handle: handle, length: n)

    var s = 16
    while s < n {
      mergePass(&aux, fromMain: true, s, n)
      s += s
      mergePass(&aux, fromMain: false, s, n)
      s += s
    }

    engine.deleteAuxArray(handle)
  }
}
