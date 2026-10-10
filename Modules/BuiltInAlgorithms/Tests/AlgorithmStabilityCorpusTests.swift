import AlgorithmKit
@testable import BuiltInAlgorithms
import SortEngineKit
import Testing

struct AlgorithmStabilityCorpusTests {
  @Test
  func pairedIterativeAndRecursiveVariantsHaveConsistentMetadata() {
    let byID = Dictionary(uniqueKeysWithValues: AllBuiltInAlgorithms.sorts.map {
      ($0.id.rawValue, $0)
    })
    var pairs = 0
    for (id, iterative) in byID where id.hasSuffix("iterative") {
      let recursiveID = String(id.dropLast("iterative".count)) + "recursive"
      guard let recursive = byID[recursiveID] else { continue }
      pairs += 1
      #expect(iterative.metadata.category == recursive.metadata.category, "\(id) / \(recursiveID)")
      #expect(iterative.metadata.sizeRange == recursive.metadata.sizeRange, "\(id) / \(recursiveID)")
      #expect(iterative.metadata.stable == recursive.metadata.stable, "\(id) / \(recursiveID)")
    }
    #expect(pairs == 11)
  }

  @Test
  func correctedUnstableMetadataHasAnEqualKeyReorderingWitness() {
    let swapOnly: [any SortAlgorithm] = [
      BoseNelsonSortRecursive(), BufferedStoogeSort(), CreaseSort(), FoldSort(),
      PairwiseMergeSortIterative(), PairwiseMergeSortRecursive(), PairwiseSortRecursive(),
      WeaveSortIterative(), WeaveSortRecursive(),
    ]
    for algorithm in swapOnly {
      #expect(!algorithm.metadata.stable)
      let size = algorithm.metadata.sizeRange.lowerBound
      let input = Self.duplicateInput(for: algorithm, size: size, seed: 0)
      var engine = RecordingEngine(values: input, operationCap: 2_000_000, randomSeed: 0)
      algorithm.record(into: &engine)
      let summary = engine.finish()
      #expect(!summary.didExceedCap)
      #expect(summary.tape.allSatisfy {
        if case .setValue = $0 {
          false
        } else {
          true
        }
      })
      var originalIndices = Array(0 ..< size)
      for operation in summary.tape {
        if case let .swap(i, j) = operation {
          originalIndices.swapAt(i, j)
        }
      }
      let hasCrossedEquals = (1 ..< size).contains { index in
        input[originalIndices[index - 1]] == input[originalIndices[index]]
          && originalIndices[index - 1] > originalIndices[index]
      }
      #expect(hasCrossedEquals, "\(algorithm.id.rawValue) no longer has the recorded instability witness")
    }

    let patience = PatienceSort()
    #expect(!patience.metadata.stable)
    let size = patience.metadata.sizeRange.lowerBound
    let radix = 128
    let input = Self.duplicateInput(for: patience, size: size, seed: 0)
      .enumerated().map { $0.element * radix + $0.offset }
    var engine = RecordingEngine(
      values: input, operationCap: 2_000_000, comparisonKeyForTesting: { $0 / radix }
    )
    patience.record(into: &engine)
    let output = engine.values
    #expect(output.map { $0 / radix } == input.map { $0 / radix }.sorted())
    #expect((1 ..< size).contains { index in
      output[index - 1] / radix == output[index] / radix
        && output[index - 1] % radix > output[index] % radix
    }, "Patience Sort no longer has the recorded instability witness")
  }

  @Test
  func swapOnlyStabilityClaimsMatchOriginalElementOrder() {
    let stable = AllBuiltInAlgorithms.sorts.filter { $0.metadata.stable }
    var failures: [String] = []
    var notSwapOnly: [String] = []
    for algorithm in stable {
      let range = algorithm.metadata.effectiveSizeRange(operationCap: RecordingEngine.defaultOperationCap)
      let sizes = algorithm.metadata.category == .impractical
        ? [range.lowerBound]
        : Set([range.lowerBound, min(32, range.upperBound), min(64, range.upperBound)]
          .filter { range.contains($0) }).sorted()
      for size in sizes {
        for seed in 0 ..< 3 {
          var state = UInt64(size * 1009 + seed * 131 + algorithm.id.rawValue.utf8.reduce(0) { $0 + Int($1) })
          let input = (0 ..< size).map { _ in
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Int((state >> 32) % 4)
          }
          var engine = RecordingEngine(values: input, operationCap: 2_000_000, randomSeed: UInt64(seed))
          algorithm.record(into: &engine)
          let summary = engine.finish()
          if summary.tape.contains(where: {
            if case .setValue = $0 {
              true
            } else {
              false
            }
          }) {
            notSwapOnly.append(algorithm.id.rawValue)
            break
          }
          if summary.didExceedCap {
            failures.append("\(algorithm.id.rawValue): capped tape")
            break
          }
          var originalIndices = Array(0 ..< size)
          for operation in summary.tape {
            if case let .swap(i, j) = operation {
              originalIndices.swapAt(i, j)
            }
          }
          for index in 1 ..< size where input[originalIndices[index - 1]] == input[originalIndices[index]] {
            if originalIndices[index - 1] >= originalIndices[index] {
              failures.append("\(algorithm.id.rawValue), size \(size), seed \(seed): unstable")
              break
            }
          }
        }
      }
    }
    print("NOT_SWAP_ONLY \(Set(notSwapOnly).sorted())")
    #expect(failures.isEmpty, "\(failures.joined(separator: "\n"))")
  }

  private static func duplicateInput(for algorithm: any SortAlgorithm, size: Int, seed: Int) -> [Int] {
    var state = UInt64(size * 1009 + seed * 131 + algorithm.id.rawValue.utf8.reduce(0) { $0 + Int($1) })
    return (0 ..< size).map { _ in
      state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
      return Int((state >> 32) % 4)
    }
  }

  @Test
  func everyDeclaredStableAlgorithmPreservesTaggedEqualKeys() {
    // These four swap-only sorts have separate in-algorithm tie handling; the test comparison
    // override changes their logic. The original-identity tape test below covers them instead.
    let stable = AllBuiltInAlgorithms.sorts.filter {
      $0.metadata.stable && !($0 is FunSort) && !($0 is ForcedStableQuickSort)
        && !($0 is TableSort) && !($0 is GrailSort)
    }
    #expect(!stable.isEmpty)
    let radix = 128
    var failures: [String] = []
    algorithmLoop: for algorithm in stable {
      let range = algorithm.metadata.effectiveSizeRange(operationCap: RecordingEngine.defaultOperationCap)
      let sizes = Set([range.lowerBound, min(32, range.upperBound), min(64, range.upperBound)]
        .filter { range.contains($0) }).sorted()
      for size in sizes {
        for seed in 0 ..< 3 {
          var state = UInt64(size * 1009 + seed * 131 + algorithm.id.rawValue.utf8.reduce(0) { $0 + Int($1) })
          let input = (0 ..< size).map { index in
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Int((state >> 32) % 4) * radix + index
          }
          var engine = RecordingEngine(
            values: input, operationCap: 2_000_000,
            comparisonKeyForTesting: { $0 / radix }
          )
          algorithm.record(into: &engine)
          let output = engine.values
          guard output.map({ $0 / radix }) == input.map({ $0 / radix }).sorted() else {
            failures.append("\(algorithm.id.rawValue), size \(size), seed \(seed): wrong key order")
            continue algorithmLoop
          }
          guard output.sorted() == input.sorted() else {
            failures.append("\(algorithm.id.rawValue), size \(size), seed \(seed): changed values")
            continue algorithmLoop
          }
          for index in 1 ..< size where output[index - 1] / radix == output[index] / radix {
            if output[index - 1] % radix >= output[index] % radix {
              failures.append("\(algorithm.id.rawValue), size \(size), seed \(seed): unstable tie")
              continue algorithmLoop
            }
          }
        }
      }
    }
    #expect(failures.isEmpty, "\(failures.joined(separator: "\n"))")
  }
}
