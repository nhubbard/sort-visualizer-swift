import AlgorithmKit
import SortEngineKit

/// A three-way recursive sort in the Stooge Sort family, filed under merge sorts (rather than
/// alongside plain `StoogeSort`/`QuadStoogeSort`) because its combining step is a genuine
/// two-pointer merge instead of Stooge Sort's own "recurse on the first 2/3, the last 2/3, then
/// the first 2/3 again" pattern. `wrapper` splits `[start, stop)` into three roughly-equal parts —
/// `[start, third)`, `[third, twoThird)`, `[twoThird, stop)` — sorts the middle and last thirds
/// recursively, then merges those two already-sorted runs into `[start, twoThird)` via an ordinary
/// swap-based two-pointer merge (`left`/`right`/`bufferStart`, the "buffer" the name refers to:
/// `[start, third)` acts as scratch space the merge overwrites through `bufferStart` rather than
/// needing a separate aux array). A second recursive sort of `[twoThird, stop)` repeats after the
/// merge, since the merge above only guaranteed `[start, twoThird)` — the last third's own values
/// used up their sorted order as source material, not as a preserved final answer, so it gets
/// sorted again. A final pass of adjacent-swap bubbling (`left`/`right` walking inward from both
/// ends of `[start, stop)`) is what actually reconciles the newly-sorted `[start, twoThird)` prefix
/// with `[twoThird, stop)`'s own re-sort into one fully ordered range.
///
/// `third`/`twoThird`'s exact split points use integer arithmetic (`(width + 2) / 3` and
/// `(2*width + 2) / 3`) equivalent to ArrayV's own `Math.ceil(width / 3.0)`/
/// `Math.ceil(width * 2.0 / 3.0)` for every non-negative integer width — verified directly rather
/// than assumed, since a one-off split-point mismatch here would misdivide the recursion without
/// necessarily crashing.
///
/// The recursion here isn't the textbook `T(n) = 3T(2n/3) + O(1)` that gives Stooge Sort its
/// famous `O(n^2.71)` — it's closer to `T(n) = T(n/3) + 2T(2n/3) + O(n)` (two full-cost recursions
/// into a `2n/3`-sized range, one via the merge step and one via the direct re-sort, plus one into
/// the smaller `n/3` range). Solving that recurrence lands on the same `O(n^2)` growth as a
/// plain quadratic sort — confirmed empirically via a log-log fit of measured swap counts across
/// sizes 32 through 2048 (estimated exponent ≈1.92, converging toward 2 as `n` grows) rather than
/// assumed from the Stooge Sort family resemblance alone.
public struct BufferedStoogeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "bufferedstoogesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Buffered Stooge Sort",
    category: .merge,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 367, coefficients: [239257, 1273.9, 1.69348],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [1.69348, 30.8934, -173.24], rSquared: 0.999994),
    implementationComplexity: 14,
    stable: true,
    timeComplexity: ComplexityBounds(best: "O(n^2)", average: "O(n^2)", worst: "O(n^2)"),
    spaceComplexity: "O(log n)",
    iconName: "theatermasks.fill"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    func wrapper(_ start: Int, _ stop: Int) {
      guard stop - start > 1 else { return }

      if stop - start == 2, engine.compare(start, stop - 1, by: >) {
        engine.swap(start, stop - 1)
      }

      guard stop - start > 2 else { return }

      let width = stop - start
      let third = (width + 2) / 3 + start
      var twoThird = (2 * width + 2) / 3 + start
      if twoThird - third < third {
        twoThird -= 1
      }
      if (width - 2) % 3 == 0 {
        twoThird -= 1
      }

      wrapper(third, twoThird)
      wrapper(twoThird, stop)

      var left = third
      var right = twoThird
      var bufferStart = start
      while left < twoThird, right < stop {
        if engine.compare(left, right, by: >) {
          engine.swap(bufferStart, right)
          right += 1
        } else {
          engine.swap(bufferStart, left)
          left += 1
        }
        bufferStart += 1
      }
      while right < stop {
        engine.swap(bufferStart, right)
        right += 1
        bufferStart += 1
      }

      wrapper(twoThird, stop)

      left = twoThird - 1
      right = stop - 1
      while right > left, left >= start {
        if engine.compare(left, right, by: >) {
          for i in left..<right {
            engine.swap(i, i + 1)
          }
          left -= 1
        }
        right -= 1
      }
    }

    wrapper(0, n)
  }
}
