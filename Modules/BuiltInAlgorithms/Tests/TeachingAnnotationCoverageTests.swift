import AlgorithmKit
import SortEngineKit
import Testing

@testable import BuiltInAlgorithms

@Suite
struct TeachingAnnotationCoverageTests {
  @Test
  func everyBuiltInSortExplainsARecordedDecision() {
    for algorithm in AllBuiltInAlgorithms.sorts {
      let minimum = algorithm.metadata.sizeRange.lowerBound
      let size = algorithm.metadata.category == .impractical
        ? minimum : min(max(minimum, 32), algorithm.metadata.sizeRange.upperBound)
      let descending = Array((0..<size).reversed())
      let duplicateHeavy = algorithm is IndexSort
        ? Array((0..<size).filter { $0.isMultiple(of: 2) }
          + (0..<size).filter { !$0.isMultiple(of: 2) })
        : (0..<size).map { ($0 * 7) % 3 }
      var hasAuthoredEvent = false

      for input in [descending, duplicateHeavy] {
        var engine = RecordingEngine(values: input)
        algorithm.record(into: &engine)
        let result = engine.finish()
        #expect(engine.values == input.sorted(), "\(algorithm.id.rawValue) changed sorting behavior")
        #expect(result.teachingAnnotations.allSatisfy {
          result.tape.indices.contains($0.operationIndex)
            && $0.explanation?.isEmpty == false
        }, "\(algorithm.id.rawValue) has an invalid teaching annotation")
        hasAuthoredEvent = hasAuthoredEvent || !result.teachingAnnotations.isEmpty
      }

      #expect(hasAuthoredEvent, "\(algorithm.id.rawValue) has no teaching explanation")
    }
  }
}
