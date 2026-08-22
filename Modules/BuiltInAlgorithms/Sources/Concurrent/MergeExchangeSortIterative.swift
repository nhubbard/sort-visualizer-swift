import AlgorithmKit
import Foundation
import SortEngineKit

public struct MergeExchangeSortIterative: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "mergeexchangesortiterative")
  public let metadata = AlgorithmMetadata(
    displayName: "Iterative Merge-Exchange Sort",
    category: .concurrent,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 1014, coefficients: [222565, 296.317, 0.0488819],
      measuredSafeCeiling: nil),
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n log^2 n)", average: "O(n log^2 n)", worst: "O(n log^2 n)"),
    spaceComplexity: "O(1)",
    iconName: "arrow.triangle.merge"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    let t = Int(log(Double(n - 1)) / log(2.0)) + 1
    let p0 = 1 << (t - 1)

    var p = p0
    while p > 0 {
      var q = p0
      var r = 0
      var d = p
      while true {
        if n - d > 0 {
          for i in 0..<(n - d) where (i & p) == r {
            if !engine.compare(i + d, i) {
              engine.swap(i, i + d)
            }
          }
        }
        if q == p { break }
        d = q - p
        q >>= 1
        r = p
      }
      p >>= 1
    }
  }
}
