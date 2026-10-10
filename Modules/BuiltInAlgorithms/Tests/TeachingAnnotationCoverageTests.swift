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

  @Test
  func everyBuiltInSortExplainsTheWholeReplay() {
    for algorithm in AllBuiltInAlgorithms.sorts {
      let minimum = algorithm.metadata.sizeRange.lowerBound
      let size = algorithm.metadata.category == .impractical
        ? minimum : min(max(minimum, 32), algorithm.metadata.sizeRange.upperBound)
      let descending = Array((0..<size).reversed())
      let duplicateHeavy = algorithm is IndexSort
        ? Array((0..<size).filter { $0.isMultiple(of: 2) }
          + (0..<size).filter { !$0.isMultiple(of: 2) })
        : (0..<size).map { ($0 * 7) % 3 }

      for input in [descending, duplicateHeavy] {
        var engine = RecordingEngine(values: input)
        algorithm.record(into: &engine)
        let result = engine.finish()
        let operationCount = result.tape.count
        guard operationCount >= 80 else { continue }
        var quartiles = [0, 0, 0, 0]
        for annotation in result.teachingAnnotations {
          let quartile = min(3, annotation.operationIndex * 4 / operationCount)
          quartiles[quartile] += 1
        }
        let totalEvents = quartiles.reduce(0, +)
        #expect(quartiles.allSatisfy { $0 > 0 },
          "\(algorithm.id.rawValue) has an empty teaching quartile: \(quartiles) across \(operationCount) operations")
        #expect((quartiles.max() ?? 0) * 4 <= totalEvents * 3,
          "\(algorithm.id.rawValue) clusters teaching events in one quartile: \(quartiles) across \(operationCount) operations")
      }
    }
  }

  @Test
  func bingoSortTeachingContinuesThroughLargeReplay() {
    for input in [Array((0..<128).reversed()), (0..<128).map { ($0 * 7) % 9 }] {
      var engine = RecordingEngine(values: input)
      BingoSort().record(into: &engine)
      let result = engine.finish()
      #expect(engine.values == input.sorted())
      let operationCount = result.tape.count
      var quartiles = [0, 0, 0, 0]
      for annotation in result.teachingAnnotations {
        quartiles[min(3, annotation.operationIndex * 4 / operationCount)] += 1
      }
      #expect(quartiles.allSatisfy { $0 > 0 },
        "Bingo Sort loses teaching context during a 128-item replay: \(quartiles)")
    }
  }

  @Test
  func practicalSortsTeachAcrossReachableDefaultSize() {
    var exercised = 0
    for algorithm in AllBuiltInAlgorithms.sorts where algorithm.metadata.category != .impractical {
      let range = algorithm.metadata.effectiveSizeRange(
        operationCap: RecordingEngine.defaultOperationCap)
      let size = min(256, range.upperBound)
      guard size >= max(32, range.lowerBound) else { continue }
      let input = Array((0..<size).reversed())
      var engine = RecordingEngine(values: input)
      algorithm.record(into: &engine)
      let result = engine.finish()
      guard !result.didExceedCap else { continue }
      exercised += 1
      #expect(engine.values == input.sorted(), "\(algorithm.id.rawValue) failed at size \(size)")
      var quartiles = [0, 0, 0, 0]
      for annotation in result.teachingAnnotations {
        quartiles[min(3, annotation.operationIndex * 4 / result.tape.count)] += 1
      }
      #expect(quartiles.allSatisfy { $0 > 0 },
        "\(algorithm.id.rawValue) misses a teaching quartile at size \(size): \(quartiles)")
      #expect((quartiles.max() ?? 0) * 4 <= quartiles.reduce(0, +) * 3,
        "\(algorithm.id.rawValue) clusters teaching at size \(size): \(quartiles)")
    }
    #expect(exercised > 150, "Too few practical sorts reached the default-size teaching check")
  }
}
