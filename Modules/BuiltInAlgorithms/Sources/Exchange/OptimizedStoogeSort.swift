import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `sorts/exchange/OptimizedStoogeSort.java`, refactored from a technique
/// described by Amit Kishor and Pankaj Pratap Singh
/// (ijitee.org/wp-content/uploads/papers/v8i12/L31671081219.pdf).
///
/// `exchange` first does one bidirectional pass pairing `values[left]`/`values[right]` while they
/// converge toward the middle (settling the global min/max into their end positions in one
/// sweep), then runs two shrinking-triangle passes: `forward` repeatedly pairs `values[left]`
/// against `values[right]` while sweeping `left` up to `right` and resets `left` to `0` each
/// outer iteration (shrinking `right` by one each time); `backward` is the mirror image, sweeping
/// `right` down to `left` and resetting `right` to its original value each outer iteration
/// (growing `left` by one each time). Distant-index compare-and-swap throughout, same family as
/// a cocktail/selection-style sort.
public struct OptimizedStoogeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "optimizedstoogesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Optimized Stooge Sort",
    category: .exchange,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 253, coefficients: [239401, 1895, 3.74998],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [3.74998, -2.49097, -0.68452], rSquared: 1),
    implementationComplexity: 13,
    stable: false,
    timeComplexity: ComplexityBounds(best: "O(n^2)", average: "O(n^2)", worst: "O(n^2)"),
    spaceComplexity: "O(1)",
    iconName: "theatermasks.fill"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    guard engine.count > 1 else { return }
    exchange(&engine, engine.count)
  }

  private func exchange(_ engine: inout RecordingEngine, _ length: Int) {
    var left = 0
    var right = length - 1
    while left < right {
      if engine.compare(left, right, by: >) {
        engine.swap(left, right)
      }
      left += 1
      right -= 1
    }
    forward(&engine, 0, length - 2)
    backward(&engine, 1, length - 1)
  }

  private func forward(_ engine: inout RecordingEngine, _ left: Int, _ right: Int) {
    var left = left
    var right = right
    while left < right {
      var index = right
      while left < index {
        if engine.compare(left, index, by: >) {
          engine.swap(left, index)
        }
        left += 1
        index -= 1
      }
      left = 0
      right -= 1
    }
  }

  private func backward(_ engine: inout RecordingEngine, _ left: Int, _ right: Int) {
    var left = left
    var right = right
    let length = right
    while left < right {
      var index = left
      while index < right {
        if engine.compare(index, right, by: >) {
          engine.swap(index, right)
        }
        index += 1
        right -= 1
      }
      left += 1
      right = length
    }
  }
}
