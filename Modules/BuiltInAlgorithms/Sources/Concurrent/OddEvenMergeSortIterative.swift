import AlgorithmKit
import SortEngineKit

public struct OddEvenMergeSortIterative: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "oddevenmergesortiterative")
  public let metadata = AlgorithmMetadata(
    displayName: "Odd-Even Merge Sort (Iterative)",
    category: .concurrent,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 897, coefficients: [239988, 392.652, 0.102345],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLaw, coefficients: [11.1341, 1.46761], rSquared: 0.993967),
    implementationComplexity: 8,
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(log^2 n)", average: "O(log^2 n)", worst: "O(log^2 n)"),
    spaceComplexity: "O(n log^2 n)",
    iconName: "arrow.left.arrow.right"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count

    var p = 1
    while p < n {
      var k = p
      while k > 0 {
        var j = k % p
        while j + k < n {
          for i in 0..<k where (i + j) / (p + p) == (i + j + k) / (p + p) {
            if i + j + k < n {
              if !engine.compare(i + j + k, i + j) {
                engine.swap(i + j, i + j + k)
              }
            }
          }
          j += k + k
        }
        k /= 2
      }
      p += p
    }
  }
}
