import AlgorithmKit
import SortEngineKit
import Testing

@testable import BuiltInAlgorithms

@Suite
struct AlgorithmDetailDataContractTests {
  @Test
  func fixedPassBubbleSortDeclaresItsQuadraticBestCase() {
    let algorithm = BubbleSort()
    #expect(algorithm.metadata.timeComplexity.best == "O(n^2)")
    for values in [Array(1...16), Array((1...16).reversed())] {
      var engine = RecordingEngine(values: values, operationCap: 1_000_000)
      algorithm.record(into: &engine)
      #expect(engine.finish().compareCount == 16 * 15 / 2)
    }
  }

  @Test
  func everyBuiltInAlgorithmHasCompleteFiniteChartAndEquationInputs() {
    #expect(!AllBuiltInAlgorithms.sorts.isEmpty)
    for algorithm in AllBuiltInAlgorithms.sorts {
      let metadata = algorithm.metadata
      let id = algorithm.id.rawValue
      #expect(!metadata.displayName.isEmpty, "\(id): missing title")
      #expect(!metadata.timeComplexity.best.isEmpty, "\(id): missing best case")
      #expect(!metadata.timeComplexity.average.isEmpty, "\(id): missing average case")
      #expect(!metadata.timeComplexity.worst.isEmpty, "\(id): missing worst case")
      #expect(!metadata.spaceComplexity.isEmpty, "\(id): missing space bound")
      guard let detected = metadata.detectedGrowthModel else {
        Issue.record("\(id): missing detected growth model")
        continue
      }
      #expect(detected.rSquared.isFinite, "\(id): invalid fit score")
      let domain = metadata.growthComparisonDomain(operationCap: 300_000)
      let lower = domain.lowerBound
      let upper = domain.upperBound
      #expect(lower > 0 && upper > lower, "\(id): invalid logarithmic chart domain")
      #expect(upper >= Double(metadata.effectiveSizeRange(operationCap: 300_000).upperBound),
        "\(id): chart excludes the selectable cutoff")
      for index in 0..<40 {
        let n = lower + Double(index) / 39 * (upper - lower)
        #expect(detected.predictedOperations(atSize: n).isFinite,
          "\(id): detected chart overflows at size \(n)")
        #expect(metadata.growthModel.predictedOperations(atSize: n).isFinite,
          "\(id): fitted chart overflows at size \(n)")
      }
    }
  }
}
