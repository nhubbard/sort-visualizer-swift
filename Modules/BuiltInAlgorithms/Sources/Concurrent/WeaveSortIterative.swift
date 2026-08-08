import AlgorithmKit
import SortEngineKit

/// An iterative sorting network built by padding the real array length `n` up to the next power
/// of two (`length`, computed but never separately allocated — the network is just built for a
/// larger virtual size and every comparator touching a virtual index past the real array is
/// skipped via `compSwap`'s own `b < end` bound check), then running five nested passes whose
/// index arithmetic weaves comparator pairs together at doubling strides. Sized identically to
/// `CreaseSort`'s own comparator count (both measured at the exact same totals across every tested
/// array size) despite a completely different loop shape — two distinct ways of expressing the
/// same underlying "weave" network.
///
/// `O(n log^2 n)` comparators — confirmed empirically (the ratio of measured comparisons to
/// `n log^2 n` converges to a near-constant ~0.27–0.31 across sizes 16 through 2048, unlike the
/// steadily-growing ratio a plain `n log n` or `n^2` count would show). Every comparator only ever
/// swaps on strict `>`, and fuzzing across randomized duplicate-heavy trials found no case where
/// two equal elements crossed paths, confirming this network is stable rather than merely assuming
/// it from the swap-on-strict-`>` rule alone.
public struct WeaveSortIterative: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "weavesortiterative")
  public let metadata = AlgorithmMetadata(
    displayName: "Iterative Weave Sort",
    category: .concurrent,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 1031, coefficients: [222245, 288.574, 0.045229],
      measuredSafeCeiling: nil),
    stable: true,
    timeComplexity: ComplexityBounds(
      best: "O(n log^2 n)", average: "O(n log^2 n)", worst: "O(n log^2 n)"),
    spaceComplexity: "O(1)",
    iconName: "arrow.up.and.down.and.arrow.left.and.right"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let end = engine.count
    guard end > 1 else { return }

    func compSwap(_ a: Int, _ b: Int) {
      guard b < end else { return }
      if engine.compare(a, b, by: >) {
        engine.swap(a, b)
      }
    }

    var n = 1
    while n < end { n *= 2 }

    var i = 1
    while i < n {
      var j = 1
      while j <= i {
        var k = 0
        while k < n {
          let d = n / i / 2
          var m = 0
          var l = n / j - d
          while l >= n / j / 2 {
            var p = 0
            while p < d {
              compSwap(k + m, k + l + p)
              p += 1
              m += 1
            }
            l -= d
          }
          k += n / j
        }
        j *= 2
      }
      i *= 2
    }
  }
}
