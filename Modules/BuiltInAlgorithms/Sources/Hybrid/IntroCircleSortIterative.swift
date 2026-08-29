import AlgorithmKit
import SortEngineKit

/// ArrayV's `IntroCircleSortIterative` — reuses `CircleSortIterative`'s `circleSortRoutine` core
/// (nested below), but caps the number of passes at `threshold` (computed like ArrayV: double `n`
/// from 1 until it reaches `end`, count the doublings, then halve). If the budget runs out before a
/// pass reports zero swaps, it falls back to one full binary insertion sort pass, giving a hard
/// `O(n^2)` worst-case ceiling instead of circle sort's unbounded repeat-until-stable loop.
///
/// Stable: `false` — same as `CircleSortIterative`, whose fold-inward compare-and-swap can reorder
/// equal elements across separate windows. The insertion sort fallback is itself stable, but can't
/// retroactively undo disordering already committed by earlier circle-sort passes.
public struct IntroCircleSortIterative: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "introcirclesortiterative")
  public let metadata = AlgorithmMetadata(
    displayName: "Intro Circle (Iterative)",
    category: .hybrid,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 829, coefficients: [239869, 499.36, 0.251911],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [0.251911, 81.6922, -977.171], rSquared: 0.999813),
    implementationComplexity: 15,
    stable: false,
    // Best/average mirror `CircleSortIterative`'s O(n log^2 n). Worst case differs: passes are
    // capped at `threshold`, then the insertion sort fallback's O(n^2) shift step dominates.
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log^2 n)", worst: "O(n^2)"),
    spaceComplexity: "O(1)",
    iconName: "arrow.down.right.and.arrow.up.left"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let end = engine.count
    guard end > 1 else { return }

    // Same padded-power-of-two `n` as `CircleSortIterative` — every real array access below
    // stays separately guarded against `end`, so `n` only ever controls how many gap/start
    // window combinations get iterated over, never an actual out-of-range read or write.
    var n = 1
    var threshold = 0
    while n < end {
      n <<= 1
      threshold += 1
    }
    threshold /= 2

    // Verbatim `IterativeCircleSorting.circleSortRoutine` translation (see
    // `CircleSortIterative.swift`): for each shrinking `gap`, slide a window of size `2 * gap`
    // across the padded conceptual array, and within each window walk `low`/`high` inward from
    // its ends toward its center.
    func circleSortRoutine(_ length: Int) -> Int {
      var swapCount = 0
      var gap = length / 2
      while gap > 0 {
        var start = 0
        while start + gap < end {
          var low = start
          var high = start + 2 * gap - 1
          while low < high {
            if high < end {
              if engine.compare(low, high, by: (>)) {
                engine.swap(low, high)
                swapCount += 1
              }
            }
            low += 1
            high -= 1
          }
          start += 2 * gap
        }
        gap /= 2
      }
      return swapCount
    }

    // ArrayV's `do { iterations++; if (iterations >= threshold) { ...; break; } }
    // while (circleSortRoutine(...) != 0)`, translated via Swift's `repeat`/`while`: iterations
    // must be incremented and checked against `threshold` before each next pass.
    var iterations = 0
    repeat {
      iterations += 1
      if iterations >= threshold {
        // Fallback: one full binary insertion sort pass, inlined rather than calling into
        // `BinaryInsertionSort`'s own `SortAlgorithm` conformance (no precedent in this
        // codebase for one algorithm invoking another).
        for i in 1..<end {
          var lo = 0
          var hi = i
          while lo < hi {
            let mid = lo + (hi - lo) / 2
            if engine.compare(i, mid, by: <) {
              hi = mid
            } else {
              lo = mid + 1
            }
          }
          var j = i
          while j > lo {
            engine.swap(j, j - 1)
            j -= 1
          }
        }
        break
      }
    } while circleSortRoutine(n) != 0
  }
}
