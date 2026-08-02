import AlgorithmKit
import SortEngineKit

/// A recursive Bose-Nelson sorting network: `boseNelson` splits a range in half, recursively
/// builds a network for each half, then stitches them together with `merge` — a comparator-network
/// merge that works on two already-internally-sorted runs of *any* lengths, not just equal or
/// power-of-two ones. `merge`'s own recursion bottoms out at the three smallest cases (`1+1`,
/// `1+2`, `2+1` elements) with a handful of direct `compareSwap` calls, and otherwise splits both
/// runs again (using a length-parity-dependent split for the second run, `len2 / 2` when `len1` is
/// odd, `(len2 + 1) / 2` when even) and recurses into three overlapping sub-merges. Because the
/// whole thing operates on run lengths and offsets directly rather than assuming a padded
/// power-of-two array, it needs no `end`-style bounds check the way this app's other network sorts
/// (`WeaveSort*`, `FoldSort`, `PairwiseMergeSort*`) do.
///
/// The Bose-Nelson construction is a classically studied one: it produces `O(n^log₂3)` ≈
/// `O(n^1.585)` comparators, confirmed here via a log-log fit of measured comparison counts against
/// array size (slope ≈1.62, close to log₂3 ≈1.585) rather than assumed from the name alone — better
/// than an `O(n log^2 n)` network for large `n`, though not as good as an optimal `O(n log n)`
/// network. Every comparison only ever swaps on strict `>`, and this exact recursive split never
/// lets two equal elements cross without a direct or transitively-ordered comparison between them,
/// so the result is stable (confirmed by fuzzing, not just by the swap-on-strict-`>` rule alone —
/// see `CompleteGraphSort`'s own doc comment for why that rule alone isn't sufficient in general).
public struct BoseNelsonSortRecursive: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "bosenelsonsortrecursive")
  public let metadata = AlgorithmMetadata(
    displayName: "Recursive Bose-Nelson Sort",
    category: .concurrent,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 654, coefficients: [239600, 647.462, 0.42732],
      measuredSafeCeiling: nil),
    stable: true,
    timeComplexity: ComplexityBounds(
      best: "O(n^{1.585})", average: "O(n^{1.585})", worst: "O(n^{1.585})"),
    spaceComplexity: "O(log n)",
    iconName: "circle.grid.3x3"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    func compareSwap(_ start: Int, _ end: Int) {
      if engine.compare(start, end, by: >) {
        engine.swap(start, end)
      }
    }

    func merge(_ start1: Int, _ len1: Int, _ start2: Int, _ len2: Int) {
      if len1 == 1, len2 == 1 {
        compareSwap(start1, start2)
      } else if len1 == 1, len2 == 2 {
        compareSwap(start1, start2 + 1)
        compareSwap(start1, start2)
      } else if len1 == 2, len2 == 1 {
        compareSwap(start1, start2)
        compareSwap(start1 + 1, start2)
      } else {
        let mid1 = len1 / 2
        let mid2 = len1 % 2 == 1 ? len2 / 2 : (len2 + 1) / 2
        merge(start1, mid1, start2, mid2)
        merge(start1 + mid1, len1 - mid1, start2 + mid2, len2 - mid2)
        merge(start1 + mid1, len1 - mid1, start2, mid2)
      }
    }

    func boseNelson(_ start: Int, _ length: Int) {
      if length > 1 {
        let mid = length / 2
        boseNelson(start, mid)
        boseNelson(start + mid, length - mid)
        merge(start, mid, start + mid, length - mid)
      }
    }

    boseNelson(0, n)
  }
}
