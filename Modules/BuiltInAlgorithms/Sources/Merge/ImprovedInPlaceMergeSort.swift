import AlgorithmKit
import SortEngineKit

/// A recursive in-place merge sort — distinct from `InPlaceMergeSort`, which this app already
/// ships. Instead of a full-size aux array, `merge`'s only moving part is `push`: given a run
/// boundary `[a, b)` and a position `p` before it, `push` grabs `array[a]` into `p`, shifts
/// everything in `(a, b)` left by one to close the gap, and drops the value `p` used to hold onto
/// the freed slot at `b - 1`. `merge` walks `i` across the left run `[a, m)`: whenever the current
/// left element is already `<= array[j]`, it's smaller than every right-run element scanned so far
/// (the ones `j` has already stepped past while `array[i] > array[j]` kept firing), so a single
/// `push(i, m, j)` slots the next unconsumed right-run element (`array[m]`, since nothing before
/// `m` has moved yet at this point in the scan) into `i`'s place and shuffles the rest down —
/// exactly the effect of "insert `array[m]` here, everyone else shifts over by one."
///
/// Because a `push` only ever touches `p`, `[a, b)`, and never anything strictly between `p` and
/// `a`, it can't be expressed as a chain of adjacent swaps the way `InPlaceLSDRadixSort`'s rotation
/// can — the gap between `p` and `a` is real and deliberately left untouched, so this is ported as
/// direct `engine.values` reads paired with `engine.setValue` writes instead.
///
/// A `push`'s cost is the width of `(a, b)`, and an already-sorted input never triggers one at all
/// (every left element is already `<= array[j]`'s untouched starting value, but `j` itself never
/// advances past `m` since the left/right runs are already in order, so every `push(i, m, m)` call
/// hits `push`'s own `a == b` short-circuit and does nothing) — best case is the ordinary
/// merge-sort comparison structure alone, `O(n log n)`. A reverse-sorted input, by contrast,
/// triggers a `push` shifting nearly the whole remaining right run on almost every step, landing
/// on `O(n^2)` — confirmed empirically (write count scales with `n^2`, not `n log n`, on adversarial
/// input) rather than assumed from the shape of the recursion alone.
public struct ImprovedInPlaceMergeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "improvedinplacemergesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Improved In-Place Merge Sort",
    category: .merge,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 661, coefficients: [239574, 704.958, 0.51783],
      measuredSafeCeiling: nil),
    stable: true,
    timeComplexity: ComplexityBounds(best: "O(n log n)", average: "O(n^2)", worst: "O(n^2)"),
    spaceComplexity: "O(log n)",
    iconName: "rectangle.arrowtriangle.2.inward"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    func push(_ p: Int, _ a: Int, _ b: Int) {
      guard a != b else { return }
      let temp = engine.values[p]
      engine.setValue(p, engine.values[a])
      for i in (a + 1)..<b {
        engine.setValue(i - 1, engine.values[i])
      }
      engine.setValue(b - 1, temp)
    }

    func merge(_ a: Int, _ m: Int, _ b: Int) {
      var i = a
      var j = m
      while i < m, j < b {
        if engine.compare(i, j, by: >) {
          j += 1
        } else {
          push(i, m, j)
          i += 1
        }
      }
      while i < m {
        push(i, m, b)
        i += 1
      }
    }

    func mergeSort(_ a: Int, _ b: Int) {
      let m = a + (b - a) / 2
      if b - a > 2 {
        if b - a > 3 {
          mergeSort(a, m)
        }
        mergeSort(m, b)
      }
      merge(a, m, b)
    }

    mergeSort(0, n)
  }
}
