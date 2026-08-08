import AlgorithmKit
import SortEngineKit

/// An iterative sorting network named for the diamond-shaped pattern its comparator offsets trace
/// across each doubling block size `m`: within a block, the offset `cnt` ramps up from `0` toward
/// `m/4` and back down toward `0` by `m/2` (`k` for the first half, `m/2 - k` for the second),
/// widening and narrowing a small window `[j+cnt, j+m-cnt)` of adjacent-pair comparisons within
/// each block as `m` doubles from `4` up to the padded power-of-two size. A final half-size pass
/// after the main loop mirrors the same widen/narrow shape one level down to finish reconciling
/// blocks. Unlike `WeaveSort*`/`FoldSort`/`PairwiseMergeSort*`, this network's inner bounds are
/// `Math.min(length, ...)`-clamped directly against the real array length rather than a separate
/// `end`-checked comparator, so it needs no virtual-padding skip.
///
/// Despite sharing a package with sorting networks that scale near-linearithmically, this one's
/// comparator count is genuinely quadratic: instrumented counts land almost exactly on `n(n-1)/2`
/// for power-of-two sizes and hold a roughly constant ~0.68–0.88 ratio to `n^2` at non-power-of-two
/// sizes too — confirmed empirically rather than assumed from the "concurrent sorting network"
/// family resemblance, which might otherwise suggest something far cheaper. Every comparator only
/// ever swaps on strict `>`, and fuzzing across randomized duplicate-heavy trials found no case
/// where two equal elements crossed paths, confirming this network is stable.
public struct DiamondSortIterative: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "diamondsortiterative")
  public let metadata = AlgorithmMetadata(
    displayName: "Diamond Sort (Iterative)",
    category: .concurrent,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 187, coefficients: [238567, 2558.99, 6.85996],
      measuredSafeCeiling: nil),
    stable: true,
    timeComplexity: ComplexityBounds(best: "O(n^2)", average: "O(n^2)", worst: "O(n^2)"),
    spaceComplexity: "O(1)",
    iconName: "diamond"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let length = engine.count
    guard length > 1 else { return }

    func compSwap(_ a: Int, _ b: Int) {
      if engine.compare(a, b, by: >) {
        engine.swap(a, b)
      }
    }

    var n = 1
    while n < length { n *= 2 }

    var m = 4
    while m <= n {
      for k in 0..<(m / 2) {
        let cnt = k <= m / 4 ? k : m / 2 - k
        var j = 0
        while j < length {
          if j + cnt + 1 < length {
            var i = j + cnt
            while i + 1 < min(length, j + m - cnt) {
              compSwap(i, i + 1)
              i += 2
            }
          }
          j += m
        }
      }
      m *= 2
    }

    m /= 2
    for k in 0...(m / 2) {
      var i = k
      while i + 1 < min(length, m - k) {
        compSwap(i, i + 1)
        i += 2
      }
    }
  }
}
