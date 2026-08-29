import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `sorts/select/BadSort.java` — a deliberately wasteful selection sort from a
/// StackOverflow answer (James Jensen / "StriplingWarrior") asking for a genuine *O*(*n*^3)
/// worst-case sort.
///
/// For each `i`, it finds the leftmost suffix minimum of `values[i..<n]` by brute force: for each
/// candidate `j` (starting at `i`), the `k`-loop scans every later index for a counterexample
/// smaller than `values[j]`; the first `j` whose `k`-scan runs clean is confirmed as the minimum and
/// swapped into `i`. This is an ordinary leftmost-minimum selection sort — it just proves "is this
/// the minimum?" via an `O(n)` scan instead of a running tracker, to manufacture a cubic worst case.
///
/// Complexity is genuinely asymmetric, not a flat *O*(*n*^3): best case (sorted ascending) and
/// reverse-sorted input are both *Θ*(*n*^2) (`n(n-1)/2` `k`-loop compares, for different structural
/// reasons); average case on random input is *Θ*(*n*^2 log n); the cubic *Θ*(*n*^3) worst case needs
/// a specific adversarial shape — `[2, 3, ..., n, 1]` — that reproduces itself on the remaining
/// suffix after every swap. That shape isn't just theoretical: this codebase's `MovedElementShuffle`
/// on sorted input with `start` near 0 and `dest` near `n-1` produces it directly.
///
/// Stable: `false`. Swap-based selection sort — `engine.swap(i, shortest)` can jump the suffix
/// minimum backward past equal-valued elements sitting between `i` and `shortest`, reordering them.
///
/// `sizeRange: 16...128` mirrors `StoogeSort`'s cap rather than `SelectionSort`'s `16...256`:
/// `BadSort`'s adversarial worst case at `n = 128` (~349,500 `k`-loop compares) is already
/// comparable to `StoogeSort`'s accepted ceiling, and the cubic growth makes `256` ~8x worse.
public struct BadSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "badsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Bad Sort",
    category: .selection,
    sizeRange: 16...128,
    growthModel: OperationGrowthModel(
      anchorSize: 80, coefficients: [235277, 9309.04, 125.981, 0.611696],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLaw, coefficients: [0.222694, 3.16531], rSquared: 0.998283),
    implementationComplexity: 7,
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n^2)", average: "O(n^2 log n)", worst: "O(n^3)"),
    spaceComplexity: "O(1)",
    iconName: "hand.thumbsdown.fill"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let count = engine.count
    guard count > 1 else { return }

    for index in 0..<count {
      var shortest = index
      var index2 = index
      while index2 < count {
        var isShortest = true
        var index2p = index2 + 1
        while index2p < count {
          // Reads.compareValues(array[j], array[k]) == 1 — strict greater-than, both
          // live indices (see the doc comment above for why this still goes through
          // `engine.compare` despite ArrayV routing it through `compareValues`).
          if engine.compare(index2, index2p, by: (>)) {
            isShortest = false
            break
          }
          index2p += 1
        }
        if isShortest {
          shortest = index2
          break
        }
        index2 += 1
      }
      engine.swap(index, shortest)
    }
  }
}
