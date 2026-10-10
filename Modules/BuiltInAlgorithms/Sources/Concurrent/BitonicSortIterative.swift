import Foundation
import AlgorithmKit
import SortEngineKit

public struct BitonicSortIterative: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "bitonicsortiterative")
  public let metadata = AlgorithmMetadata(
    displayName: String(localized: "Bitonic Sort (Iterative)", bundle: .module),
    category: .concurrent,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 818, coefficients: [239600, 425.432, 0.117653],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLaw, coefficients: [14.0899, 1.45243], rSquared: 0.991791),
    implementationComplexity: 10,
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(log^2 n)", average: "O(log^2 n)", worst: "O(log^2 n)"),
    spaceComplexity: "O(n log^2 n)",
    iconName: "waveform"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count

    var k = 2
    while k < n * 2 {
      let m = ((n + (k - 1)) / k) % 2 != 0

      var j = k >> 1
      while j > 0 {
        for i in 0..<n {
          let ij = i ^ j
          if ij > i && ij < n {
            let ascending = ((i & k) == 0) == m
            let ordered = ascending ? engine.compare(ij, i) : engine.compare(i, ij)
            engine.annotateLastOperation(
              stageID: "bitonicMerge", decisionID: "bitonicsortiterative.directionalComparator",
              outcome: ordered ? "keep" : "exchange",
              roles: ["left": .arrayIndex(i), "right": .arrayIndex(ij)],
              explanationKey: "bitonicsortiterative.directionalComparator",
              explanation: ordered
                ? String(localized: "This pair fits the current bitonic merge direction, so keep it.", bundle: .module)
                : String(localized: "This pair opposes the current bitonic merge direction, so exchange it.", bundle: .module))
            if !ordered {
              engine.swap(i, ij)
            }
          }
        }
        j = j >> 1
      }

      k = 2 * k
    }
  }
}
