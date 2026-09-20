import AlgorithmKit
import SortEngineKit

public struct OddEvenMergeSortIterative: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "oddevenmergesortiterative")
  public let metadata = AlgorithmMetadata(
    displayName: "Odd-Even Merge Sort (Iterative)",
    category: .concurrent,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 895, coefficients: [239630, 393.237, 0.102968],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLaw, coefficients: [11.0709, 1.46871], rSquared: 0.99385),
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
